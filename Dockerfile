# syntax=docker/dockerfile:1

#
# Carrot2 Dockerfile
#
# This Dockerfile builds a Carrot2 image with optional language extensions.
#

# The core Carrot2 JAR supports a limited set of popular languages.
# Additional language modules can be added for Chinese, Japanese, and Korean.
#
# To install extensions, set the CARROT2_LANG_EXTENSIONS build argument, for example:
# --build-arg CARROT2_LANG_EXTENSIONS="chinese,japanese"

################################################################################
# Build stage: download and unpack Carrot2 distribution.
################################################################################
FROM eclipse-temurin:21-jdk-jammy AS build

ARG CARROT2_VERSION=4.8.4
ARG CARROT2_CHECKSUM_SHA256=31fc65c15e2f02e46e1c2e629ef72958d234e8d8d0b0dcc169d1409ccfc79002
ARG CARROT2_URL=https://github.com/carrot2/carrot2/releases/download/release%2F${CARROT2_VERSION}/carrot2-${CARROT2_VERSION}.zip

ARG CARROT2_LANG_EXTENSIONS="chinese,japanese,korean"
ARG LUCENE_CJK_VERSION=10.3.2

# Install dependencies for downloading and unpacking
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download, verify, and unpack Carrot2
WORKDIR /build
RUN curl -fsSL -o carrot2.zip "${CARROT2_URL}" && \
    echo "${CARROT2_CHECKSUM_SHA256}  carrot2.zip" | sha256sum -c - && \
    unzip carrot2.zip && \
    rm carrot2.zip

# Add language extensions, if requested.
ARG MAVEN_BASE_URL=https://repo1.maven.org/maven2
ARG GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/carrot2/carrot2/master

# Copy the helper script for downloading language extensions.
COPY scripts/download_helpers.sh /build/download_helpers.sh

# Set directories for language extensions
ENV LIB_DIR="carrot2-${CARROT2_VERSION}/dcs/web/service/WEB-INF/lib"
ENV RESOURCES_DIR="carrot2-${CARROT2_VERSION}/dcs/web/service/resources"

# Install Chinese language pack if requested
RUN echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "chinese" && \
    ( \
      set -e; \
      . /build/download_helpers.sh; \
      echo "Installing Chinese language pack"; \
      download_jar "${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-chinese/${CARROT2_VERSION}/carrot2-lang-lucene-chinese-${CARROT2_VERSION}.jar"; \
      download_jar "${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-smartcn/${LUCENE_CJK_VERSION}/lucene-analysis-smartcn-${LUCENE_CJK_VERSION}.jar"; \
      download_jar "${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-icu/${LUCENE_CJK_VERSION}/lucene-analysis-icu-${LUCENE_CJK_VERSION}.jar"; \
      base_resource_url="${GITHUB_RAW_BASE_URL}/lang/lucene-chinese/src/main/resources/org/carrot2/language/chinese"; \
      download_resource "${base_resource_url}/chinese-simplified.label-filters.json" "chinese-simplified.label-filters.json"; \
      download_resource "${base_resource_url}/chinese-simplified.word-filters.json" "chinese-simplified.word-filters.json"; \
      download_resource "${base_resource_url}/chinese-traditional.label-filters.json" "chinese-traditional.label-filters.json"; \
      download_resource "${base_resource_url}/chinese-traditional.word-filters.json" "chinese-traditional.word-filters.json"; \
    )

# Install Japanese language pack if requested
RUN echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "japanese" && \
    ( \
      set -e; \
      . /build/download_helpers.sh; \
      echo "Installing Japanese language pack"; \
      download_jar "${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-japanese/${CARROT2_VERSION}/carrot2-lang-lucene-japanese-${CARROT2_VERSION}.jar"; \
      download_jar "${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-kuromoji/${LUCENE_CJK_VERSION}/lucene-analysis-kuromoji-${LUCENE_CJK_VERSION}.jar"; \
      base_resource_url="${GITHUB_RAW_BASE_URL}/lang/lucene-japanese/src/main/resources/org/carrot2/language/japanese"; \
      download_resource "${base_resource_url}/japanese.label-filters.json" "japanese.label-filters.json"; \
      download_resource "${base_resource_url}/japanese.word-filters.json" "japanese.word-filters.json"; \
    )

# Install Korean language pack if requested
RUN echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "korean" && \
    ( \
      set -e; \
      . /build/download_helpers.sh; \
      echo "Installing Korean language pack"; \
      download_jar "${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-korean/${CARROT2_VERSION}/carrot2-lang-lucene-korean-${CARROT2_VERSION}.jar"; \
      download_jar "${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-nori/${LUCENE_CJK_VERSION}/lucene-analysis-nori-${LUCENE_CJK_VERSION}.jar"; \
      base_resource_url="${GITHUB_RAW_BASE_URL}/lang/lucene-korean/src/main/resources/org/carrot2/language/korean"; \
      download_resource "${base_resource_url}/korean.label-filters.json" "korean.label-filters.json"; \
      download_resource "${base_resource_url}/korean.word-filters.json" "korean.word-filters.json"; \
    )

# Clean up the helper script
RUN rm /build/download_helpers.sh


################################################################################
# Final stage: create the runtime image.
################################################################################
FROM eclipse-temurin:21-jre-alpine AS final

LABEL maintainer="Carrot2 project"
LABEL org.opencontainers.image.title="Carrot2"
LABEL org.opencontainers.image.description="Carrot2 is an open source search results clustering engine."
LABEL org.opencontainers.image.url="https://search.carrot2.org/"
LABEL org.opencontainers.image.source="https://github.com/carrot2/carrot2-docker"
LABEL org.opencontainers.image.vendor="Carrot2 project"

ARG CARROT2_VERSION=4.8.4
LABEL org.opencontainers.image.version="${CARROT2_VERSION}"

# Environment variables
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${PATH}:${JAVA_HOME}/bin"
ENV JAVA_OPTS="-Xms256m -Xmx1g"

# Create a non-privileged user and group for enhanced security
RUN addgroup --system carrot2 && \
    adduser \
        --system \
        --ingroup carrot2 \
        --disabled-password \
        --gecos "" \
        --home "/opt/carrot2" \
        --shell "/sbin/nologin" \
        carrot2

# Set workdir
WORKDIR /opt/carrot2

# Copy Carrot2 from the build stage and set permissions
COPY --from=build --chown=carrot2:carrot2 /build/carrot2-${CARROT2_VERSION}/ /opt/carrot2/
COPY --chown=carrot2:carrot2 carrot2.LICENSE carrot2.NOTICE ./

# Create and set permissions for the data volume
VOLUME /opt/carrot2/data

# Expose Carrot2 port
EXPOSE 8080

# Switch to the non-privileged user
USER carrot2

WORKDIR /opt/carrot2/dcs
# Run DCS (Workbench UI at /, docs at /doc, API at /service)
CMD ["./dcs", "--port", "8080"]

# Health check to verify service availability
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/service/list || exit 1
