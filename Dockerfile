ARG CONTEXT=prod

FROM traefik:v3.5.0 as base

## Setup
ARG CONTEXT
WORKDIR /app
ENV APP_CONTEXT=${CONTEXT}

# curl for healthcheck, gettext for templating (envsubst)
RUN apk add --no-cache curl gettext

# Copy configuration files
COPY traefik.yml /etc/traefik/traefik.yml
COPY entrypoint /entrypoint
COPY certs /certs
COPY services /services
COPY templates /templates

# Create dynamic config directory and make entrypoint executable
RUN mkdir -p /etc/traefik/dynamic && \
    chmod +x /entrypoint

## External Information
LABEL org.opencontainers.image.title="OpenSlides Traefik Proxy"
LABEL org.opencontainers.image.description="The Traefik proxy is the entrypoint for traffic going into an OpenSlides instance."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/OpenSlides/OpenSlides/tree/main/openslides-proxy"

## Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/ping || exit 1

## Command
ENTRYPOINT ["/entrypoint"]

# Development Image
FROM base as dev

ENV ENABLE_LOCAL_HTTPS=1
ENV TRAEFIK_LOG_LEVEL=DEBUG

# Default service hosts and ports for development
ENV ACTION_HOST=backend
ENV ACTION_PORT=9002
ENV PRESENTER_HOST=backend
ENV PRESENTER_PORT=9003
ENV AUTOUPDATE_HOST=autoupdate
ENV AUTOUPDATE_PORT=9012
ENV SEARCH_HOST=search
ENV SEARCH_PORT=9050
ENV AUTH_HOST=auth
ENV AUTH_PORT=9004
ENV CLIENT_HOST=client
ENV CLIENT_PORT=9001
ENV ICC_HOST=icc
ENV ICC_PORT=9007
ENV MEDIA_HOST=media
ENV MEDIA_PORT=9006
ENV MANAGE_HOST=manage
ENV MANAGE_PORT=9008
ENV VOTE_HOST=vote
ENV VOTE_PORT=9013

# Testing Image
FROM base as tests

# Production Image
FROM base as prod

# Add appuser for security
RUN adduser -S -D -H appuser
RUN chown -R appuser /app/ && \
    chown -R appuser /etc/traefik/ && \
    chown appuser /entrypoint

USER appuser