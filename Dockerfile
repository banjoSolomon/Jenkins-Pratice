FROM maven:3.8.7 as build
COPY . .
RUN mvn -B clean package -DskipTests -X

FROM openjdk:17
COPY --from=build target/*.jar jenkins.jar
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "jenkins.jar"]
