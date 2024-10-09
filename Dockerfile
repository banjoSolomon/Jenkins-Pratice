# Use Maven to build the application
FROM maven:3.8.7 AS build

# Copy the project files into the container
COPY . .

# Build the application without running tests
RUN mvn -B clean package -DskipTests

# Use OpenJDK to run the application
FROM openjdk:17

# Copy the built JAR file from the build stage
COPY --from=build target/*.jar jenkins.jar

# Set the active Spring profile (if needed, otherwise you can comment this out)
# ENV SPRING_PROFILES_ACTIVE=${PROFILE}

# Set the command to run the application
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "jenkins.jar"]
