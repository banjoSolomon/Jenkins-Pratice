# Use a slimmer base image for Java
FROM openjdk:17-jdk-slim

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

# Copy the Maven settings file if needed
COPY settings.xml /home/appuser/.m2/settings.xml

# Make the mvnw script executable
RUN chmod +x mvnw

# Package your application with Maven
# This assumes you have a pom.xml in the current directory
RUN ./mvnw clean package -DskipTests

# Set the entry point for your application
ENTRYPOINT ["java", "-jar", "-Dserver.port=8080", "target/Jenkins-Pratice.jar"]

# Expose the application's default port
EXPOSE 8080
