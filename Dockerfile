FROM maven:3.8.7 AS build

# Copy your local m2 directory to the Docker image
COPY ~/.m2 /root/.m2

WORKDIR /app
COPY . .
RUN mvn -B clean package -DskipTests

FROM openjdk:17-slim
WORKDIR /app
COPY --from=build /app/target/*.jar Jenkins.jar
EXPOSE 9090
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins.jar"]