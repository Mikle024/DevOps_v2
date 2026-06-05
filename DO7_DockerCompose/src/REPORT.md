
<!-- TOC -->
* [Part 1.](#part-1)
  * [Локальный запуск сервисов](#локальный-запуск-сервисов)
  * [Использование докер для запуска сервисов](#использование-докер-для-запуска-сервисов)
<!-- TOC -->

# Part 1.

## Локальный запуск сервисов

1. Написал [docker-compose.yml](docker-compose.yml), где задекларировал 2 контейнера:
    - **postgres_db** от образа `postgres:13` с инициализацией баз [init.sql](services/database/init.sql), с пользователем
      **postgres** от лица которого сервисы будут заполнять эти бд и проброшенным портом `5432`

    - **rabbitmq_service** от образа `rabbitmq:3-management-alpine`, с пользователем и паролем **guest**,
      так же с проброшенным портом `5672` для сервиса и `15672` для админ-панели

    - завязал их в общую сеть `backend`
    - задекларировал том `postgres_data` для сохранения данных бд в случае перезапуска

```yaml
services:
  postgres:
    container_name: postgres_db
    image: postgres:13
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./services/database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend

  rabbitmq:
    container_name: rabbitmq_service
    image: rabbitmq:3-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    networks:
      - backend

volumes:
  postgres_data:

networks:
  backend:
```

2. Запустил контейнеры командой `docker compose up -d`

3. Установил актуальную версию **JVM** и **JDK** командой `sudo apt install default-jdk`

4. Установил менеджер процессов **pm2** *(Process Manager 2)*, для начальной безконтейнерной сборки сервисов.

5. Изучил документацию [04-project_rus.md](../materials/04-project_rus.md), общую архитектуру
   и необходимый набор переменных окружения для запуска каждого сервиса.

6. Используя менеджер пакетов **Maven** и его обертки **mvnw**, находясь в директориях с каждым [сервисом](services), выполнил команду `./mvnw package -DskipTests`

7. Убедился в создании директорий `target/` со всеми зависимостями.


8. Поочередно запустил каждый сервис *(находясь в соответствующих директориях)* с помощью менеджера процессов **pm2**:
- **session_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=users_db java -jar target/*.jar" --name "session_service"
```
- **hotel_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=hotels_db java -jar target/*.jar" --name "hotel_service"
```
- **payment_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=payments_db java -jar target/*.jar" --name "payment_service"
```
- **loyalty_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=balances_db java -jar target/*.jar" --name "loyalty_service"
```
- **report_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=statistics_db RABBIT_MQ_HOST=localhost RABBIT_MQ_PORT=5672 RABBIT_MQ_USER=guest RABBIT_MQ_PASSWORD=guest RABBIT_MQ_QUEUE_NAME=messagequeue RABBIT_MQ_EXCHANGE=messagequeue-exchange java -jar target/*.jar" --name "report_service"
```
- **booking_service**:
```bash
pm2 start "POSTGRES_HOST=localhost POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=password POSTGRES_DB=reservations_db RABBIT_MQ_HOST=localhost RABBIT_MQ_PORT=5672 RABBIT_MQ_USER=guest RABBIT_MQ_PASSWORD=guest RABBIT_MQ_QUEUE_NAME=messagequeue RABBIT_MQ_EXCHANGE=messagequeue-exchange HOTEL_SERVICE_HOST=localhost HOTEL_SERVICE_PORT=8082 PAYMENT_SERVICE_HOST=localhost PAYMENT_SERVICE_PORT=8084 LOYALTY_SERVICE_HOST=localhost LOYALTY_SERVICE_PORT=8085 java -jar target/*.jar" --name "booking_service"
```
- **gateway_service**:
```bash
pm2 start "SESSION_SERVICE_HOST=localhost SESSION_SERVICE_PORT=8081 HOTEL_SERVICE_HOST=localhost HOTEL_SERVICE_PORT=8082 BOOKING_SERVICE_HOST=localhost BOOKING_SERVICE_PORT=8083 PAYMENT_SERVICE_HOST=localhost PAYMENT_SERVICE_PORT=8084 LOYALTY_SERVICE_HOST=localhost LOYALTY_SERVICE_PORT=8085 REPORT_SERVICE_HOST=localhost REPORT_SERVICE_PORT=8086 java -jar target/*.jar" --name "gateway_service"
```


>  Запущенные сервисы через **Process Manager 2**:
>
> ![screen_1_01.png](screen/screen_1_01.png)
>

9. Установил и запустил **Postman**:
   - Импортировал [коллекцию](application_tests.postman_collection.json)
   - Адаптировал коллекцию для работы, указав ip-адрес VM.
   - Запустил тесты нажав `Run` в верхнем правом углу и удостоверился, что все они прошли успешно.

>  Успешно завершенные тесты в **Postman**:
>
> <img src="screen/screen_1_02.png" width="60%" />
>

- После остановил контейнеры **postgres_db** и **rabbitmq_service** командой `docker compose down -v`
- и запущенные сервисы в **pm2** командой `pm2 delete {0..6}`

---

## Использование докер для запуска сервисов

- Написал базовый **Dockerfile** для каждого сервиса

>
> ![screen_1_03.png](screen/screen_1_03.png)
>

- Разбор **Dockerfile** на примере **session-service**:

```dockerfile
# берем легковесный образ Alpine Linux с установленным JDK 21
FROM eclipse-temurin:21-jdk-alpine

# создаем внутри контейнера рабочую директорию /opt/session-service
WORKDIR /opt/session-service

# копируем директорию .mvn с настройками Maven Wrapper в рабочую директорию
COPY .mvn .mvn
# копируем исполняемый файл сборщика mvnw и файл конфигурации зависимостей pom.xml в рабочую директорию
COPY mvnw pom.xml ./
# выдаем докеру права на исполнение файла mvnw
RUN chmod +x mvnw
# запускаем mvnw, который скачивает все сторонние зависимости из интернета
RUN ./mvnw dependency:go-offline

# копируем директорию src с исходным кодом java-сервиса в рабочую директорию контейнера
COPY src src

# запускаем компиляцию
# maven компилирует код и упаковывает его в готовый jar-файл внутри директории target/
# флаг -DskipTests отключает тесты для ускорения процесса
RUN ./mvnw package -DskipTests

# документируем, что session-service внутри контейнера слушает порт 8081
EXPOSE 8081

# запускаем java-сервис внутри контейнера
ENTRYPOINT ["sh", "-c", "java -jar target/*.jar"]
```

- Создал тестовые образы на базе текущих докерфайлов:
   - находясь в директории [services](services) выполнил команды:

```bash
docker build -t session-service-test session-service/
```

```bash
docker build -t hotel-service-test hotel-service/
```

```bash
docker build -t booking-service-test booking-service/
```

```bash
docker build -t payment-service-test payment-service/
```

```bash
docker build -t loyalty-service-test loyalty-service/
```

```bash
docker build -t report-service-test report-service/
```

```bash
docker build -t gateway-service-test gateway-service/
```

>  Размер собранных образов в текущей сборке:
>
> ![screen_1_04.png](screen/screen_1_04.png)
>

- Запустил контейнеры **postgres_db** и **rabbitmq_service** командой `docker compose up -d`

- Запустил каждый контейнер с сервисами по отдельности командами:


- **session-service**:
```bash
docker run --rm -p 8081:8081 -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=users_db --network src_backend --name session-service -d session-service-test
```
- **hotel-service**:
```bash
docker run --rm -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=hotels_db --network src_backend --name hotel-service -d hotel-service-test
```
- **payment-service**:
```bash
docker run --rm -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=payments_db --network src_backend --name payment-service -d payment-service-test
```
- **loyalty-service**:
```bash
docker run --rm -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=balances_db --network src_backend --name loyalty-service -d loyalty-service-test
```
- **report-service**:
```bash
docker run --rm -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=statistics_db -e RABBIT_MQ_HOST=rabbitmq_service -e RABBIT_MQ_PORT=5672 -e RABBIT_MQ_USER=guest -e RABBIT_MQ_PASSWORD=guest -e RABBIT_MQ_QUEUE_NAME=messagequeue -e RABBIT_MQ_EXCHANGE=messagequeue-exchange --network src_backend --name report-service -d report-service-test
```
- **booking-service**:
```bash
docker run --rm -e POSTGRES_HOST=postgres_db -e POSTGRES_PORT=5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=reservations_db -e RABBIT_MQ_HOST=rabbitmq_service -e RABBIT_MQ_PORT=5672 -e RABBIT_MQ_USER=guest -e RABBIT_MQ_PASSWORD=guest -e RABBIT_MQ_QUEUE_NAME=messagequeue -e RABBIT_MQ_EXCHANGE=messagequeue-exchange -e HOTEL_SERVICE_HOST=hotel-service -e HOTEL_SERVICE_PORT=8082 -e PAYMENT_SERVICE_HOST=payment-service -e PAYMENT_SERVICE_PORT=8084 -e LOYALTY_SERVICE_HOST=loyalty-service -e LOYALTY_SERVICE_PORT=8085 --network src_backend --name booking-service -d booking-service-test
```
- **gateway-service**:
```bash
docker run --rm -p 8087:8087 -e SESSION_SERVICE_HOST=session-service -e SESSION_SERVICE_PORT=8081 -e HOTEL_SERVICE_HOST=hotel-service -e HOTEL_SERVICE_PORT=8082 -e BOOKING_SERVICE_HOST=booking-service  -e BOOKING_SERVICE_PORT=8083 -e PAYMENT_SERVICE_HOST=payment-service -e PAYMENT_SERVICE_PORT=8084 -e LOYALTY_SERVICE_HOST=loyalty-service -e LOYALTY_SERVICE_PORT=8085 -e REPORT_SERVICE_HOST=report-service -e REPORT_SERVICE_PORT=8086 --network src_backend --name gateway-service -d gateway-service-test
```


- Т.к. в текущих конфигурациях **Dockerfile** мы не использовали скрипт `wait-for-it.sh`, то после запуска каждого контейнера ожидаем, пока каждый из них настраивает внутренние процессы, перед запуском следующего

>  Успешный запуск **session-service**:
>
> ![screen_1_05.png](screen/screen_1_05.png)
>

>  Успешный запуск **hotel-service**:
>
> ![screen_1_06.png](screen/screen_1_06.png)
>

>  Успешный запуск **payment-service**:
>
> ![screen_1_07.png](screen/screen_1_07.png)
>

>  Успешный запуск **loyalty-service**:
>
> ![screen_1_08.png](screen/screen_1_08.png)
>

>  Успешный запуск **report-service**:
>
> ![screen_1_09.png](screen/screen_1_09.png)
>

>  Успешный запуск **booking-service**:
>
> ![screen_1_10.png](screen/screen_1_10.png)
>

>  Успешный запуск **gateway-service**:
>
> ![screen_1_11.png](screen/screen_1_11.png)
>

- Запустил тесты в **Postman** и удостоверился, что все они прошли успешно.

>  Успешно завершенные тесты в **Postman**:
>
> <img src="screen/screen_1_12.png" width="60%" />
>

>  Логи сервиса **gateway** во время тестов:
>
> ![screen_1_13.png](screen/screen_1_13.png)
>

>  Внесенные изменения в таблицу **payments** после тестов:
>
> ![screen_1_14.png](screen/screen_1_14.png)
>
> ![screen_1_15.png](screen/screen_1_15.png)
>

- Остановил контейнеры с бд и брокером сообщений командой `docker compose down -v`
- Остановил все контейнеры с сервисами `docker stop $(docker ps -q)`
- Удалил созданную докер сеть `docker network rm src_backend`
- Для полной очистки докера, безвозвратно удалив все неиспользуемые контейнеры, сети, образы и тома данных можно использовать `sudo docker system prune -a --volumes -f` *(осторожно)*
