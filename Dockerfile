
FROM maven:3.9.5-openjdk-17 AS builder

# Set the working directory
WORKDIR /app

# Copy the pom.xml and any other necessary files first
COPY pom.xml .
COPY src ./src

# Build the application (this will create the jar in the target directory)
RUN mvn clean package -DskipTests

# Second stage: Create a smaller image for running the application
FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy the built jar from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose the default port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar", "-Djenkins.install.runSetupWizard=false"]
