FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /opt/loyalty-service

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src src

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /opt/loyalty-service

RUN apk add --no-cache bash
RUN addgroup -S spring && adduser -S spring -G spring
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x ./wait-for-it.sh
RUN chown -R spring:spring /opt/loyalty-service

USER spring:spring

COPY --from=builder /opt/loyalty-service/target/*.jar app.jar

EXPOSE 8085

ENTRYPOINT ["./wait-for-it.sh", "-s", "postgres:5432", "--", \
            "java", "-jar", "app.jar"]