# First stage: Build the application
FROM maven:3.8.7 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the source code to the working directory
COPY . .

RUN mvn -B clean package -DskipTests

# Second stage: Create a lightweight runtime image
FROM openjdk:17

# Set the working directory for the runtime stage
WORKDIR /app

# Copy the built JAR file from the 'build' stage to the runtime image
COPY --from=build /app/target/*.jar Jenkins-Pratice.jar

# Expose the port your application will run on
EXPOSE 9090

# Command to run the application
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins-Pratice.jar"]
