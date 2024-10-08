# Stage 1: Build stage with Maven
FROM maven:3.8.7 AS build

# Set the working directory
WORKDIR /app

# Copy only the pom.xml to leverage Docker caching
COPY pom.xml .

# Download dependencies (cache this layer)
RUN mvn dependency:go-offline

# Now copy the source code
COPY src ./src

# Build the application
RUN mvn -B clean package -DskipTests

# Stage 2: Final slim image
FROM openjdk:17-slim

# Set the working directory
WORKDIR /app

# Copy the packaged JAR file from the build stage
COPY --from=build /app/target/*.jar Jenkins.jar

# Expose the application port
EXPOSE 9090

# Set the entry point to run the JAR
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins.jar"]
