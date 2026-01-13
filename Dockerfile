# syntax=docker/dockerfile:1

#
# Carrot2 Dockerfile
#
# This Dockerfile builds a Carrot2 image for ARM64 architecture.
#

################################################################################
# Build stage: download and unpack Carrot2 distribution.
################################################################################
FROM eclipse-temurin:21-jdk-jammy AS build

ARG CARROT2_VERSION=4.8.4
ARG CARROT2_CHECKSUM_SHA256=31fc65c15e2f02e46e1c2e629ef72958d234e8d8d0b0dcc169d1409ccfc79002
ARG CARROT2_URL=https://github.com/carrot2/carrot2/releases/download/release%2F${CARROT2_VERSION}/carrot2-${CARROT2_VERSION}.zip

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
