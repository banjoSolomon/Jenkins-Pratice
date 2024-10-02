# Use the official Debian base image
FROM debian:bookworm

# Set environment variables to suppress prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install curl and any other necessary dependencies
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Install Docker using the convenience script
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh

# Optional: Set Docker to run as a service
RUN systemctl enable docker
