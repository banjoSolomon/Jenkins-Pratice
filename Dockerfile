# Use the official Debian base image
FROM debian:bookworm

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive


# Install Docker from the default Debian repositories
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*
