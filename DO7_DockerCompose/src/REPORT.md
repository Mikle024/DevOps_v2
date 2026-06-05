
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