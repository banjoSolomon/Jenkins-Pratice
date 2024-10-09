# Use a Maven image to build the application
FROM maven:3.8.7 AS build


COPY . .
RUN mvn -B clean package -DskipTests -X

# Use a Java image to run the application
FROM openjdk:17
COPY --from=build target/Jenkins-Pratice.jar /app/Jenkins-Pratice.jar

# Set the entry point for your application
ENTRYPOINT ["java", "-jar", "/app/Jenkins-Pratice.jar"]

# Expose the application's default port
EXPOSE 8080
