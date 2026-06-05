FROM eclipse-temurin:21-jdk-alpine

WORKDIR /opt/hotel-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline

COPY src src

RUN ./mvnw package -DskipTests

EXPOSE 8082

ENTRYPOINT ["sh", "-c", "java -jar target/*.jar"]