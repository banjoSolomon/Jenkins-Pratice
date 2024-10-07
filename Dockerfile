FROM openjdk:17-jdk-slim

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and create a non-root user
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m appuser && \
    curl -fsSL https://get.jenkins.io/war-stable/latest/jenkins.war -o jenkins.war && \
    chown appuser:appuser jenkins.war

# Switch to non-root user
USER appuser

# Set the working directory
WORKDIR /app

# Set entry point for the container
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]

# Expose the Jenkins port
EXPOSE 8080
