FROM eclipse-temurin:21-jdk-alpine

WORKDIR /opt/report-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline

COPY src src

RUN ./mvnw package -DskipTests

EXPOSE 8086

ENTRYPOINT ["sh", "-c", "java -jar target/*.jar"]