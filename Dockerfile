# Use a specific version of a base image to ensure consistency
FROM debian:bookworm-slim

# Set environment variables (optional)
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and clean up in a single RUN command
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and switch to that user (optional but recommended for security)
RUN useradd -m appuser
USER appuser

# Copy your application files
COPY --chown=appuser:appuser . /app
WORKDIR /app

# Set the entry point to start Jenkins automatically
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]

# Expose Jenkins default port (optional)
EXPOSE 8080
