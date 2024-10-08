# Use a specific version of Maven for consistency
FROM maven:3.8.7 AS build

# Set the working directory
WORKDIR /app

# Copy only the necessary files first to leverage cache
COPY pom.xml .
COPY src ./src

# Perform a dependency install first to cache layers
RUN mvn dependency:go-offline

# Build the application while skipping tests
RUN mvn -B clean package -DskipTests

FROM openjdk:17

# Set the working directory for the final image
WORKDIR /app

# Copy the packaged JAR file from the build stage
COPY --from=build /app/target/*.jar Jenkins.jar

# Expose the application port
EXPOSE 9090

# Use exec form of ENTRYPOINT.
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins.jar"]