# syntax=docker/dockerfile:1

#
# Carrot2-CJK Dockerfile
# Supports amd64 and arm64 architectures
#
# Build arguments:
#   CARROT2_VARIANT: Set to "cjk" to build with CJK support (or use tag suffix -cjk)
#

################################################################################
# Build stage: download and unpack Carrot2-CJK distribution.
################################################################################
FROM --platform=$BUILDPLATFORM eclipse-temurin:25-jdk-noble AS build

ARG CARROT2_VERSION=4.8.6
ARG CARROT2_VARIANT
ARG CARROT2_CHECKSUM_SHA256=1f4b4a2b13e681deef6180c86eb6f15f8c03b294b048108504d253fc986fd848
ARG CARROT2_CJK_CHECKSUM_SHA256=79e0d8e0d63dfa9428179c695fb719c2c0d9e1002b67191f0d21031de12b87ac
ARG CARROT2_CJK_VERSION_SUFFIX=-1
ARG CARROT2_URL=https://github.com/carrot2/carrot2/releases/download/release%2F${CARROT2_VERSION}/carrot2-${CARROT2_VERSION}.zip
ARG CARROT2_CJK_URL=https://github.com/chriskyfung/carrot2-cjk/releases/download/release%2F${CARROT2_VERSION}-cjk${CARROT2_CJK_VERSION_SUFFIX}/carrot2-cjk-${CARROT2_VERSION}${CARROT2_CJK_VERSION_SUFFIX}.zip

# Install dependencies for downloading and unpacking
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy download helper scripts
COPY --chmod=0755 scripts/download_helpers.sh /tmp/download_helpers.sh

# Select URL based on CARROT2_VARIANT
# If CARROT2_VARIANT is "cjk", use CARROT2_CJK_URL; otherwise use CARROT2_URL
WORKDIR /build
RUN . /tmp/download_helpers.sh && \
    echo "CARROT2_VARIANT: $CARROT2_VARIANT" && \
    if [ "$CARROT2_VARIANT" = "cjk" ]; then \
        DOWNLOAD_URL="${CARROT2_CJK_URL}"; \
        CHECKSUM="${CARROT2_CJK_CHECKSUM_SHA256}"; \
    else \
        DOWNLOAD_URL="${CARROT2_URL}"; \
        CHECKSUM="${CARROT2_CHECKSUM_SHA256}"; \
    fi && \
    echo "Downloading from: ${DOWNLOAD_URL}" && \
    LOCAL_FILE=$(download_and_verify "${DOWNLOAD_URL}" "${CHECKSUM}") && \
    mv "${LOCAL_FILE}" carrot2.zip && \
    unzip carrot2.zip && \
    rm carrot2.zip

################################################################################
# Final stage: create the runtime image.
################################################################################
FROM eclipse-temurin:25-jre-noble AS final

LABEL org.opencontainers.image.title="Carrot2"
LABEL org.opencontainers.image.description="Carrot2 is an open source search results clustering engine."
LABEL org.opencontainers.image.url="https://search.carrot2.org/"
LABEL org.opencontainers.image.source="https://github.com/chriskyfung/carrot2-stack"
LABEL org.opencontainers.image.authors="Chris K.Y. Fung (@chriskyfung)"

ARG CARROT2_VERSION=4.8.6
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
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080 && echo -e "GET /service/list HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3 && grep -q "HTTP/1.1 2" <&3'
