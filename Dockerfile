FROM maven:3.9.0 as build
COPY . .
RUN mvn clean package -DskipTests -X

FROM openjdk:17
COPY --from=build target/*.jar jenkins.jar
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "jenkins.jar"]