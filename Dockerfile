# Use the official Jenkins LTS image from Docker Hub
FROM jenkins/jenkins:lts

# Skip the Jenkins setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Install Maven
USER root
RUN apt-get update && \
    apt-get install -y maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* # Clean up to reduce image size

# Switch back to Jenkins user
USER jenkins

# Install necessary plugins
RUN jenkins-plugin-cli --plugins "workflow-aggregator git"

# Expose Jenkins web interface port and Jenkins agent port
EXPOSE 8080
EXPOSE 50000

# Define default Jenkins volume for persistence
VOLUME /var/jenkins_home

# Start Jenkins
CMD ["jenkins"]
