# Use a lightweight base image (Alpine) for OpenJDK 17
FROM openjdk:17-alpine

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install only the required packages using Alpine's package manager
RUN apk add --no-cache curl git

# Create a non-root user
RUN adduser -D appuser

# Set the working directory
WORKDIR /app

# Download the latest jenkins.war as root
RUN curl -fsSL https://get.jenkins.io/war-stable/latest/jenkins.war -o jenkins.war && \
    chown appuser:appuser jenkins.war

# Switch to non-root user
USER appuser

# Set entry point for the container
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]

# Expose the Jenkins port
EXPOSE 8080
