# First stage: Build the application using Maven
FROM maven:3.8.7 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the project files into the working directory
COPY pom.xml .
COPY src ./src

# Build the application, allowing Jenkins to handle test execution if necessary
RUN mvn -B clean package -DskipTests

# Second stage: Use a lightweight OpenJDK image for running the app
FROM openjdk:17-slim

# Set the working directory for the runtime environment
WORKDIR /app

# Copy the built JAR file from the build stage to this stage
COPY --from=build /app/target/*.jar Jenkins.jar

# Expose the application's port
EXPOSE 9090

# Specify the entry point for the container
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins.jar"]
