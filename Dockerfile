# syntax=docker/dockerfile:1

#
# Carrot2 Dockerfile
#
# This Dockerfile builds a Carrot2 image.
#

# The core Carrot2 JAR supports only a limited set of popular languages. Additional modules add support for other languages and bring in extra resources required for these languages to work properly.
# 
# All language extensions live under the `org.carrot2.lang` artifact group namespace. Note that many of them come with sizeable own dependencies like [Apache Lucene](https://lucene.apache.org/) analyzers or dictionaries.
# 
# * `carrot2-lang-lucene-chinese`: Chinese (traditional and simplified).
# * `carrot2-lang-lucene-japanese`: Japanese.
# * `carrot2-lang-lucene-korean`: Korean.
#
# Extend the Docker image by adding the official org.carrot2.lang artifacts for Lucene-based analyzers and tokenizers.
# You can find their information and dependencies at https://mvnrepository.com/artifact/org.carrot2.lang/carrot2-lang-lucene-chinese/4.8.4,
# https://mvnrepository.com/artifact/org.carrot2.lang/carrot2-lang-lucene-japanese/4.8.4, and 
# https://mvnrepository.com/artifact/org.carrot2.lang/carrot2-lang-lucene-korean/4.8.4.
#

################################################################################
# Build stage: download and unpack Carrot2 distribution.
################################################################################
FROM eclipse-temurin:21-jdk-jammy AS build

ARG CARROT2_VERSION=4.8.4
ARG CARROT2_CHECKSUM_SHA256=31fc65c15e2f02e46e1c2e629ef72958d234e8d8d0b0dcc169d1409ccfc79002
ARG CARROT2_URL=https://github.com/carrot2/carrot2/releases/download/release%2F${CARROT2_VERSION}/carrot2-${CARROT2_VERSION}.zip

ARG CARROT2_LANG_EXTENSIONS="chinese japanese korean"
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

ARG CARROT2_LANG_CHINESE_URL=${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-chinese/${CARROT2_VERSION}/carrot2-lang-lucene-chinese-${CARROT2_VERSION}.jar
ARG LUCENE_ANALYSIS_SMARTCN_URL=${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-smartcn/${LUCENE_CJK_VERSION}/lucene-analysis-smartcn-${LUCENE_CJK_VERSION}.jar
ARG LUCENE_ANALYSIS_ICU_URL=${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-icu/${LUCENE_CJK_VERSION}/lucene-analysis-icu-${LUCENE_CJK_VERSION}.jar

ARG CARROT2_LANG_JAPANESE_URL=${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-japanese/${CARROT2_VERSION}/carrot2-lang-lucene-japanese-${CARROT2_VERSION}.jar
ARG LUCENE_ANALYSIS_KUROMOJI_URL=${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-kuromoji/${LUCENE_CJK_VERSION}/lucene-analysis-kuromoji-${LUCENE_CJK_VERSION}.jar

ARG CARROT2_LANG_KOREAN_URL=${MAVEN_BASE_URL}/org/carrot2/lang/carrot2-lang-lucene-korean/${CARROT2_VERSION}/carrot2-lang-lucene-korean-${CARROT2_VERSION}.jar
ARG LUCENE_ANALYSIS_NORI_URL=${MAVEN_BASE_URL}/org/apache/lucene/lucene-analysis-nori/${LUCENE_CJK_VERSION}/lucene-analysis-nori-${LUCENE_CJK_VERSION}.jar

RUN <<EOF
set -e
if [ -n "$CARROT2_LANG_EXTENSIONS" ]; then
    echo "CARROT2_LANG_EXTENSIONS is set to: ${CARROT2_LANG_EXTENSIONS}"
    cd carrot2-${CARROT2_VERSION}/dcs/web/service/WEB-INF/lib

    download_jar() {
        local url="$1"
        local filename=$(basename "$url")
        echo "Downloading $filename"
        curl -fsSLO "$url"
        curl -fsSLO "$url.sha256"
        echo "$(cat $filename.sha256) $filename" | sha256sum -c -
        rm "$filename.sha256"
    }

    if echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "chinese"; then
        echo "Installing Chinese language pack"
        download_jar "${CARROT2_LANG_CHINESE_URL}"
        download_jar "${LUCENE_ANALYSIS_SMARTCN_URL}"
        download_jar "${LUCENE_ANALYSIS_ICU_URL}"
    fi

    if echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "japanese"; then
        echo "Installing Japanese language pack"
        download_jar "${CARROT2_LANG_JAPANESE_URL}"
        download_jar "${LUCENE_ANALYSIS_KUROMOJI_URL}"
    fi

    if echo "${CARROT2_LANG_EXTENSIONS}" | grep -q -e "cjk" -e "korean"; then
        echo "Installing Korean language pack"
        download_jar "${CARROT2_LANG_KOREAN_URL}"
        download_jar "${LUCENE_ANALYSIS_NORI_URL}"
    fi
fi
EOF


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

# Create a non-privileged user and group
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

# Copy Carrot2 from the build stage
COPY --from=build /build/carrot2-${CARROT2_VERSION}/ /opt/carrot2/
COPY --chown=carrot2:carrot2 . .

# Create and set permissions for the data volume
VOLUME /opt/carrot2/data

# Expose Carrot2 port
EXPOSE 8080

# Set user
USER carrot2

WORKDIR /opt/carrot2/dcs
# Run DCS (Workbench UI at /, docs at /doc, API at /service)
CMD ["./dcs", "--port", "8080"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/service/list || exit 1
