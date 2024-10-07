FROM maven:3.8.7 as build
COPY . .
RUN mvn -B clean package -DskipTests

FROM openjdk:17
COPY --from=build target/*.jar Jenkins-pratice.jar
EXPOSE 9090

# Removed the problematic backtick
ENTRYPOINT ["java", "-jar", "-Dserver.port=9090", "Jenkins-pratice.jar"]
