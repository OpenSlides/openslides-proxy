#!/bin/sh

if [ "$APP_CONTEXT" = "dev" ]; then
    echo "Starting Traefik in development mode..."
    exec traefik
fi

if [ "$APP_CONTEXT" = "prod" ]; then
    echo "Starting Traefik in production mode..."
    exec traefik
fi

if [ "$APP_CONTEXT" = "tests" ]; then
    echo "Starting Traefik in test mode..."
    exec traefik
fi
