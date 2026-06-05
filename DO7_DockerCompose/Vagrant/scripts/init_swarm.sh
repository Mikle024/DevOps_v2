#!/bin/bash

ROLE=$1
MASTER_IP="192.168.10.100"
TOKEN_FILE="/vagrant/worker_token"

if [ "$ROLE" = "manager" ]; then
    echo "=== Initializing the Docker Swarm Wizard ==="
    docker swarm init --advertise-addr $MASTER_IP

    docker swarm join-token worker -q > $TOKEN_FILE
    echo "The token was successfully saved in $TOKEN_FILE"

elif [ "$ROLE" = "worker" ]; then
    echo "=== Connecting a worker to Docker Swarm ==="

    COUNTER=0
    while [ ! -f $TOKEN_FILE ] && [ $COUNTER -lt 30 ]; do
        echo "Waiting for a token from the master node..."
        sleep 2
        COUNTER=$((COUNTER+2))
    done

    if [ -f $TOKEN_FILE ]; then
        TOKEN=$(cat $TOKEN_FILE)
        docker swarm join --token $TOKEN $MASTER_IP:2377
    else
        echo "ERROR: The token file was not found. Couldn't connect to Swarm"
        exit 1
    fi
fi