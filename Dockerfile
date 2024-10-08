# Stage 1: Build the application with OpenJDK 17 and Maven
FROM openjdk:17 AS build
WORKDIR /app

# Install Maven
RUN apt-get update && apt-get install -y maven

# Copy only necessary files to build the application
COPY pom.xml .
COPY src/ ./src

# Build the application, skipping tests
RUN mvn -B clean package -DskipTests

# Stage 2: Create the runtime image with OpenJDK 17
FROM openjdk:17
WORKDIR /app

# Copy the built jar from the build stage
COPY --from=build /app/target/Jenkins-practice-1.0-SNAPSHOT.jar Jenkins-practice.jar

# Expose the application port
EXPOSE 9090

# Entry point to run the application
ENTRYPOINT ["java", "-Dserver.port=9090", "-jar", "Jenkins-practice.jar"]
