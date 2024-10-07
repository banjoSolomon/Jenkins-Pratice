# Use a Debian-based OpenJDK image
FROM openjdk:17-jdk-slim

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m appuser

# Set the working directory and make it writable
WORKDIR /app
RUN chown appuser:appuser /app

# Switch to non-root user
USER appuser

# Download the latest jenkins.war
RUN curl -fsSL https://get.jenkins.io/war-stable/latest/jenkins.war -o jenkins.war

# Set entry point for the container
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]

# Expose the Jenkins port
EXPOSE 8080
