FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /opt/report-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src src

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /opt/report-service

RUN apk add --no-cache bash
RUN addgroup -S spring && adduser -S spring -G spring
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x ./wait-for-it.sh
RUN chown -R spring:spring /opt/report-service

USER spring:spring

COPY --from=builder /opt/report-service/target/*.jar app.jar

EXPOSE 8086

ENTRYPOINT ["./wait-for-it.sh", "-s", "postgres:5432", "--",  \
            "./wait-for-it.sh", "-s", "--timeout=30",  "rabbitmq:5672", "--", \
            "java", "-jar", "app.jar"]