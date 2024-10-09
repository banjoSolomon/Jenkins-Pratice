# Use Maven to build the application
FROM maven:3.8.7 AS build

# Set the working directory
WORKDIR /app

# Copy the project files into the container
COPY . .

# Build the application without running tests (with verbose logging)
RUN mvn -B clean package -DskipTests -X

# Use OpenJDK to run the application
FROM openjdk:17
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Set the entry point for the application
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "app.jar"]
