# Multiservice application example

You can find an example of a multiservice application in the `./src/` folder . Below is its conceptual diagram.

<img src="misc/images/project_diagram.png"  width="800">

The project is written in Java (JDK 8), but you don't need to know Java to deploy it in Docker containers. Knowing what dependencies it needs and how the individual services relate to each other is sufficient.

The application itself is a room booking service. Or rather, its backend. It consists of nine parts, or services in Docker Compose terminology:

1. Postgres database.
2. Message queue — rabbitmq.
3. Session service — user sessions manager service.
4. Hotel service — hotel entities manager service.
5. Payment service — payment manager service.
6. Loyalty service — loyalty program manager service.
7. Report service — statistic collector service.
8. Booking service — reservation manager service.
9. Gateway service — facade for interaction with the rest of the microservices

Let's start with the first two services. For RabbitMQ, it is best to use the standard image since no additional configuration is needed (e.g., `rabbitmq:3-management-alpine`).

The corresponding services automatically populate the initial values of the PostgreSQL databases, but the databases themselves must be created by running the script: `src\services\database\init.sql`.

For the other services, you have to work harder. There are several options, but we will only consider two of them.

## 1. Local build of JAR packages

Applications written in Java are executed in a special virtual machine called the Java Virtual Machine (JVM). These applications are packaged as JAR files, which contain the program code and all necessary dependencies. The simplest way to run a Java program is to build the project locally using the package manager Maven and its wrapper MavenWrapper (MavenWrapper is in the folder with each service) by running the command: `./mvnw package -DskipTests`. The first build of the first project may take a long time. Afterwards, the resulting JAR file in the generated target folder will be the executable file.

Now, in the Dockerfile on the base, for example, `openjdk:21-jdk-alpine`, it is sufficient to specify instructions to copy the built project and run it with the command `java -jar target/*.jar`.

P.S. It's important to note that most services require a deployed PostgreSQL service to start correctly, so don't forget the `wait-for-it.sh` script.

P.P.S. To avoid using the frequently changed `latest` tag, it is important to specify the exact tag of the base image. *Publicly available images do not change.*

## 2. Building inside Docker

The problems with the previous approach become obvious when you try this option. There is too much manual work. So, we move on to building inside Docker.

To do so, create a working directory inside the image, move all the necessary build files there, and then build.

Additionally, the Maven manager supports a separate dependency connection, which is the longest process in the build. Separating this step from the build is an optimization based on the nature of Docker image layers. All dependencies are contained in a separate file, `pom.xml`, so the plan for the new Dockerfile is as follows:

1. Create a working directory.
2. Import the Maven wrapper and `pom.xml`.
3. Install the project dependencies using the following command: `./mvnw dependency:go-offline`.
4. Copy the project source code.
5. Build the project using the same approach as before, or run it with the command: `./mvnw spring-boot:run`.

P.S. To reduce the size of the final image, use the multi-stage build approach, since not all the files used in the build are needed at runtime.

## What needs to be considered?

Services in Java expect a certain set of environment variables:

### Session service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: users_db

### Hotel service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: hotels_db

### Payment service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: payments_db

### Loyalty service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: balances_db

### Report service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: statistics_db
- RABBIT_MQ_HOST: <host queue>
- RABBIT_MQ_PORT: 5672
- RABBIT_MQ_USER: guest
- RABBIT_MQ_PASSWORD: guest
- RABBIT_MQ_QUEUE_NAME: messagequeue
- RABBIT_MQ_EXCHANGE: messagequeue-exchange

### Booking service

- POSTGRES_HOST: <database host>
- POSTGRES_PORT: 5432
- POSTGRES_USER : postgres (may differ)
- POSTGRES_PASSWORD: "postgres" (may differ)
- POSTGRES_DB: reservations_db
- RABBIT_MQ_HOST: <host queue>
- RABBIT_MQ_PORT: 5672
- RABBIT_MQ_USER: guest
- RABBIT_MQ_PASSWORD: guest
- RABBIT_MQ_QUEUE_NAME: messagequeue
- RABBIT_MQ_EXCHANGE: messagequeue-exchange
- HOTEL_SERVICE_HOST: <hotel service host >
- HOTEL_SERVICE_PORT: 8082
- PAYMENT_SERVICE_HOST: <payment service host>
- PAYMENT_SERVICE_PORT: 8084
- LOYALTY_SERVICE_HOST: <loyalty service host>
- LOYALTY_SERVICE_PORT: 8085

### Gateway service

- SESSION_SERVICE_HOST: <session service host>
- SESSION_SERVICE_PORT: 8081
- HOTEL_SERVICE_HOST: <hotel service host>
- HOTEL_SERVICE_PORT: 8082
- BOOKING_SERVICE_HOST: <booking service host>
- BOOKING_SERVICE_PORT: 8083
- PAYMENT_SERVICE_HOST: <payment service host>
- PAYMENT_SERVICE_PORT: 8084
- LOYALTY_SERVICE_HOST: <loyalty service host>
- LOYALTY_SERVICE_PORT: 8085
- REPORT_SERVICE_HOST: <report service host>
- REPORT_SERVICE_PORT: 8086

Services are open on the corresponding local ports:
- Session service — 8081;
- Hotel service — 8082;
- Booking service — 8083;
- Payment service — 8084;
- Loyalty service — 8085;
- Report service — 8086;
- Gateway service — 8087.



