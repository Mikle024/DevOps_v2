FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /opt/gateway-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src src

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /opt/gateway-service

RUN apk add --no-cache bash
RUN addgroup -S spring && adduser -S spring -G spring
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x ./wait-for-it.sh
RUN chown -R spring:spring /opt/gateway-service

USER spring:spring

COPY --from=builder /opt/gateway-service/target/*.jar app.jar

EXPOSE 8087

ENTRYPOINT ["./wait-for-it.sh", "-s", "--timeout=60", "session-service:8081", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "hotel-service:8082", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "payment-service:8084", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "loyalty-service:8085", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "report-service:8086", "--", \
            "./wait-for-it.sh", "-s", "--timeout=60", "booking-service:8083", "--", \
            "java", "-jar", "app.jar"]