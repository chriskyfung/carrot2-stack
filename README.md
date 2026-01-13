# 🥕 Carrot2 Dockerized Deployment

This project provides a Dockerized setup for deploying Carrot2 v4.8.4, focusing on optimization, security, and ease of deployment. It leverages Docker multi-stage builds for efficient image creation and integrates with Cloudflare Tunnel for secure exposure.

## 📜 Project Overview

The core of this project is to package the Carrot2 v4.8.4 application into a lightweight and secure Docker image. Key features include:

*   **Optimized Dockerfile:** Uses multi-stage builds to separate build dependencies from the final runtime image, resulting in a smaller footprint. It also follows security best practices by creating and running as a non-root user.
*   **Carrot2 v4.8.4 Installation:** Installs Carrot2 from its official GitHub releases, with checksum verification to ensure integrity.
*   **Persistent Data:** Carrot2's data directory (`/opt/carrot2/data`) is configured as a Docker volume to persist data across container restarts.
*   **Cloudflare Tunnel Integration:** The `compose.yaml` includes a `cloudflared` service to expose the Carrot2 instance securely to the internet via a Cloudflare Tunnel.

## 🚀 Getting Started

### 🔧 Building the Docker Image

The Docker image can be built directly from the `Dockerfile`. The `CARROT2_VERSION` build argument can be used to specify a different version of Carrot2.

```bash
# Build the default version
docker build . -t carrot2:latest

# Build a specific version
docker build --build-arg CARROT2_VERSION=4.8.4 . -t carrot2:4.8.4
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

## 📝 Development Conventions

*   **Dockerfile:** Follows Docker best practices, including multi-stage builds, non-root user execution, and explicit environment variable settings (`JAVA_HOME`, `JAVA_OPTS`).
*   **Checksum Verification:** Ensures the integrity of the downloaded Carrot2 binaries.
*   **Health Checks:** Integrated into both the `Dockerfile` and `compose.yaml` for robust service monitoring.
*   **Image Metadata:** Includes OCI image labels for better traceability and understanding of the image.

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).

Carrot2 is distributed under its own [license](carrot2.LICENSE). Please see the `carrot2.LICENSE` and `carrot2.NOTICE` files for details.
