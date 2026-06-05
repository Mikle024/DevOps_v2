#!/bin/bash

APP_DIR="/home/vagrant/app"
STACK_NAME="app"

echo "=== Deploy stack on worker ==="

if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR" || exit 1

    echo "Launching docker stack deployment..."
    docker stack deploy -c docker-compose.yml $STACK_NAME

    echo "Waiting for initialization of services..."
    sleep 25
    docker stack ls
    docker stack ps $STACK_NAME
    docker stack services $STACK_NAME

else
    echo "ERROR: The application directory $APP_DIR was not found. Deployment cancelled!"
    exit 1
fi