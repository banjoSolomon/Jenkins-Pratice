# First stage: Build the application
FROM maven:3.8.7 AS build

WORKDIR /app

COPY . .

# Mount the Maven cache to avoid downloading dependencies each time
VOLUME /root/.m2

# Build the project without running tests
RUN mvn -B clean package -DskipTests

# Second stage: Create a lightweight runtime image
FROM openjdk:17

WORKDIR /app

COPY --from=build /app/target/*.jar Jenkins-Practice.jar

EXPOSE 9090

ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins-Practice.jar"]
