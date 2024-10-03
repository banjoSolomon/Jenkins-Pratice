# Use a slimmer base image for Java
FROM openjdk:17-jre-slim

# Set environment variables (optional)
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and clean up in a single RUN command
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and switch to that user for security
RUN useradd -m appuser
USER appuser

# Copy your application files
COPY --chown=appuser:appuser . /app
WORKDIR /app

# Set the entry point for Jenkins
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]

# Expose the Jenkins default port
EXPOSE 8080
