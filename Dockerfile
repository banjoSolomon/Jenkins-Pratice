# Use Maven 3.9.0 for building the application
FROM maven:3.9.0 AS build

# Set the working directory
WORKDIR /app

# Copy the pom.xml and the source code into the container
COPY pom.xml .
COPY src ./src

# Run Maven to build the project, skipping tests for the build
RUN mvn clean package -DskipTests -X

# Use OpenJDK 17 for running the application
FROM openjdk:17

# Copy the built JAR file from the previous stage
COPY --from=build /app/target/*.jar jenkins.jar

# Set the entry point for the application
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "jenkins.jar"]
