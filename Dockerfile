
FROM openjdk:17-jdk-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser
USER appuser

COPY --chown=appuser:appuser . /app
WORKDIR /app
ENTRYPOINT ["java", "-jar", "-Djenkins.install.runSetupWizard=false", "jenkins.war"]
EXPOSE 8080
