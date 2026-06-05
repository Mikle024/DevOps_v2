FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /opt/booking-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src src

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /opt/booking-service

RUN apk add --no-cache bash
RUN addgroup -S spring && adduser -S spring -G spring
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x ./wait-for-it.sh
RUN chown -R spring:spring /opt/booking-service

USER spring:spring

COPY --from=builder /opt/booking-service/target/*.jar app.jar

EXPOSE 8083

ENTRYPOINT ["./wait-for-it.sh", "-s", "postgres:5432", "--", \
            "./wait-for-it.sh", "-s", "--timeout=30", "rabbitmq:5672", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "hotel-service:8082", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "payment-service:8084", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "loyalty-service:8085", "--", \
            "java", "-jar", "app.jar"]