# Use the official Debian base image
FROM debian:bookworm

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 && \
    rm -rf /var/lib/apt/lists/* && \
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    # Set up the Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    # Install Docker CLI
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Set up your application
# (Add your application setup here)

# Set the entrypoint or command for your container
# CMD ["your-command"]
