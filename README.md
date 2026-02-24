# 🥕 Carrot2-CJK Dockerized Deployment

[![Docker Image Version](https://img.shields.io/docker/v/chriskyfung/carrot2?sort=semver&logo=docker&label=docker%20hub)](https://hub.docker.com/r/chriskyfung/carrot2) ![Docker Image Size](https://img.shields.io/docker/image-size/chriskyfung/carrot2?sort=semver&color=green) ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/chriskyfung/carrot2/latest-cjk?label=cjk%20image%20size&color=yellow) ![Docker Pulls](https://img.shields.io/docker/pulls/chriskyfung/carrot2?color=lightgray)
[![Carrot2 License](https://img.shields.io/badge/License-BSD_3--Clause-orange.svg)](https://github.com/carrot2/carrot2/blob/master/carrot2.LICENSE)

This project provides a Dockerized setup for deploying [Carrot2-CJK](https://github.com/chriskyfung/carrot2-cjk), a Carrot2 distribution with built-in Chinese, Japanese, and Korean language support. The setup focuses on optimization, security, and ease of deployment, leveraging Docker multi-stage builds and integrating with Cloudflare Tunnel for secure exposure.

## 📜 Project Overview

The core of this project is to package the Carrot2-CJK application into a lightweight and secure Docker image. Key features include:

*   **Optimized Dockerfile:** Uses multi-stage builds to separate build dependencies from the final runtime image, resulting in a smaller footprint. It also follows security best practices by creating and running as a non-root user.
*   **Carrot2-CJK Versioning:** The version of Carrot2-CJK to install is parameterized, and SHA256 checksum verification is used to ensure the integrity of the downloaded binaries.
*   **Built-in CJK Language Support:** The image includes Chinese, Japanese, and Korean language extensions by default.
*   **Persistent Data:** Carrot2's data directory (`/opt/carrot2/data`) is configured as a Docker volume to persist data across container restarts.
*   **Cloudflare Tunnel Integration:** The `compose.yaml` includes a `cloudflared` service to expose the Carrot2 instance securely to the internet via a Cloudflare Tunnel.

## 🚀 Getting Started

### 🔧 Building the Docker Image

The Docker image can be built directly from the `Dockerfile`. Build arguments can be used to customize the build.

*   `CARROT2_VERSION`: The version of Carrot2-CJK to install (default: `4.8.4`).
*   `CARROT2_CHECKSUM_SHA256`: The SHA256 checksum of the Carrot2-CJK zip file.

```bash
# Build the default version (with CJK support)
docker build . -t carrot2-cjk:latest

# Build a specific version with checksum verification
docker build \
  --build-arg CARROT2_VERSION=4.8.4 \
  --build-arg CARROT2_CHECKSUM_SHA256=7b152b3679bf2933944a0145dd21e46301864e0dfa4b1ca077b1c081ccb32799 \
  . -t carrot2-cjk:4.8.4
```

### 🏃 Running with Docker Compose

The `compose.yaml` file provides a simple way to run both the Carrot2 service and the `cloudflared` tunnel.

1.  **Configure Cloudflare Tunnel Token:**
    Create a file at `.secrets/tunnel_token.txt` and place your Cloudflare Tunnel token inside it. You can obtain a token from the Cloudflare Zero Trust dashboard.

    ```plaintext
    your-cloudflare-tunnel-token-here
    ```

2.  **Start the Services:**
    Navigate to the project root and execute the following command:

    ```bash
    docker compose up -d
    ```

    This command will build the image if it doesn't exist, and then start the `carrot2` and `cloudflared` services in detached mode. Carrot2 will be accessible publicly through your configured Cloudflare Tunnel.

    The Carrot2 DCS (Document Clustering Service) will be available at:
    - Workbench UI: `http://localhost:8080/`
    - Documentation: `http://localhost:8080/doc`
    - API: `http://localhost:8080/service`

## 📝 Development Conventions

*   **Dockerfile:** Follows Docker best practices, including:
    - Multi-stage builds (build stage with JDK, final stage with JRE)
    - Non-root user execution (`carrot2` user)
    - Explicit environment variable settings (`JAVA_HOME`, `JAVA_OPTS`)
    - OCI image labels for traceability
*   **Checksum Verification:** Ensures the integrity of the downloaded Carrot2-CJK binaries.
*   **Health Checks:** Integrated into both the `Dockerfile` and `compose.yaml` for robust service monitoring.
*   **Network Isolation:** Services communicate over a dedicated bridge network (`carrot2-net`).
*   **Secrets Management:** Cloudflare Tunnel token is managed via Docker secrets.

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).

Carrot2 is distributed under its own [license](carrot2.LICENSE). Please see the `carrot2.LICENSE` and `carrot2.NOTICE` files for details.
