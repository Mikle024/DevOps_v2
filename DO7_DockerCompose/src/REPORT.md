
<!-- TOC -->
* [Part 1.](#part-1)
  * [Локальный запуск сервисов](#локальный-запуск-сервисов)
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