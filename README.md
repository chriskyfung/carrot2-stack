# 🥕 Carrot2 Dockerized Deployment

This project provides a Dockerized setup for deploying Carrot2, focusing on optimization, security, and ease of deployment. It leverages Docker multi-stage builds for efficient image creation, includes optional support for Chinese, Japanese, and Korean (CJK) languages, and integrates with Cloudflare Tunnel for secure exposure.

## 📜 Project Overview

The core of this project is to package the Carrot2 application into a lightweight and secure Docker image. Key features include:

*   **Optimized Dockerfile:** Uses multi-stage builds to separate build dependencies from the final runtime image, resulting in a smaller footprint. It also follows security best practices by creating and running as a non-root user.
*   **Carrot2 Versioning:** The version of Carrot2 to install is parameterized, and checksum verification is used to ensure the integrity of the downloaded binaries.
*   **CJK Language Support:** Optional installation of Chinese, Japanese, and Korean language extensions.
*   **Persistent Data:** Carrot2's data directory (`/opt/carrot2/data`) is configured as a Docker volume to persist data across container restarts.
*   **Cloudflare Tunnel Integration:** The `compose.yaml` includes a `cloudflared` service to expose the Carrot2 instance securely to the internet via a Cloudflare Tunnel.

## 🚀 Getting Started

### 🔧 Building the Docker Image

The Docker image can be built directly from the `Dockerfile`. Several build arguments can be used to customize the build.

*   `CARROT2_VERSION`: The version of Carrot2 to install.
*   `CARROT2_CHECKSUM_SHA256`: The SHA256 checksum of the Carrot2 zip file.
*   `CARROT2_LANG_EXTENSIONS`: A comma-separated list of language extensions to install (e.g., "chinese,japanese,korean").

```bash
# Build the default version (with CJK support)
docker build . -t carrot2:latest

# Build a specific version without CJK support
docker build \
  --build-arg CARROT2_VERSION=4.8.4 \
  --build-arg CARROT2_CHECKSUM_SHA256=31fc65c15e2f02e46e1c2e629ef72958d234e8d8d0b0dcc169d1409ccfc79002 \
  --build-arg CARROT2_LANG_EXTENSIONS="" \
  . -t carrot2:4.8.4
```

### 🏃 Running with Docker Compose

The `compose.yaml` file provides a simple way to run both the Carrot2 service and the `cloudflared` tunnel. The default `compose.yaml` builds an image with CJK support.

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

## 📝 Development Conventions

*   **Dockerfile:** Follows Docker best practices, including multi-stage builds to download and install Carrot2 and its language extensions, non-root user execution, and explicit environment variable settings (`JAVA_HOME`, `JAVA_OPTS`).
*   **Checksum Verification:** Ensures the integrity of the downloaded Carrot2 binaries.
*   **Health Checks:** Integrated into both the `Dockerfile` and `compose.yaml` for robust service monitoring.
*   **Image Metadata:** Includes OCI image labels for better traceability and understanding of the image.
*   **Language Extensions:** The `Dockerfile` is designed to be easily extended with additional language packs by modifying the build arguments and adding the necessary download and installation steps.

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).

Carrot2 is distributed under its own [license](carrot2.LICENSE). Please see the `carrot2.LICENSE` and `carrot2.NOTICE` files for details.
