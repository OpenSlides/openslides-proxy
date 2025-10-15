# OpenSlides Traefik Proxy Service

The OpenSlides Traefik proxy service is a reverse proxy based on [Traefik](https://traefik.io/) that
routes all external traffic to the appropriate OpenSlides services.

## Overview

This service:

- Provides HTTPS termination with self-signed certificates for development
- Routes requests to appropriate microservices based on URL paths
- Handles WebSocket connections for real-time features
- Supports gRPC communication for the manage service

## Configuration

The proxy service is configured through:

- `traefik.yml` - Static configuration
- `entrypoint`  - Dynamic configuration generation based on environment variables

### Environment Variables

- `ENABLE_LOCAL_HTTPS` - Enable HTTPS with local certificates (default: 1 for dev)
- `TRAEFIK_LOG_LEVEL` - Log level (default: INFO)
- Service locations can be configured via `*_HOST` and `*_PORT` variables

## License

This service is part of OpenSlides and licensed under the MIT license.