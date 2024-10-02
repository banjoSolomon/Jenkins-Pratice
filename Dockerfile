FROM jenkins/jenkins:lts

# Install Maven
USER root
RUN apt-get update && apt-get install -y maven

# Install Docker (Optional, if you want to run Docker commands in Jenkins)
RUN apt-get update && \
    apt-get install -y apt-transport-https \
    ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Make sure Jenkins can run Docker commands
RUN usermod -aG docker jenkins

USER jenkins
