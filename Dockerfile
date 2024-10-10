# Use a Maven image to build the application
FROM maven:3.8.7 AS build

COPY . .
RUN mvn -B clean package -DskipTests -X

# Use a Java image to run the application
FROM openjdk:17
COPY --from=build target/demo-0.0.1-SNAPSHOT.jar /app/Jenkins.jar


# Set the entry point for your application
ENTRYPOINT ["java", "-jar", "/app/Jenkins.jar"]

# Expose the application's default port
EXPOSE 8080
