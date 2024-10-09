# Use the official Jenkins LTS image from Docker Hub
FROM jenkins/jenkins:lts

# Skip the Jenkins setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Install specific version of Maven
USER root
RUN apt-get update && \
    apt-get install -y maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to Jenkins user
USER jenkins

# Install necessary plugins
RUN jenkins-plugin-cli --plugins "workflow-aggregator git"

# Add a health check to monitor Jenkins
HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
  CMD curl -f http://localhost:8080/login || exit 1

# Expose Jenkins web interface port and Jenkins agent port
EXPOSE 8080
EXPOSE 50000

# Define default Jenkins volume for persistence
VOLUME /var/jenkins_home

# Start Jenkins
CMD ["jenkins"]
