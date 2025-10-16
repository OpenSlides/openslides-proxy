ARG CONTEXT=prod

FROM caddy:2.3.0-alpine AS base

## Setup
ARG CONTEXT
WORKDIR /app
ENV APP_CONTEXT=${CONTEXT}

## Installs
RUN apk update && apk add --no-cache \
    jq \
    gettext

COPY caddy_base.json /caddy_base.json
COPY entrypoint /entrypoint
COPY certs /certs

## External Information
LABEL org.opencontainers.image.title="OpenSlides Proxy"
LABEL org.opencontainers.image.description="The proxy is the entrypoint for traffic going into an OpenSlides instance."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/OpenSlides/OpenSlides/tree/main/proxy"

## Command
ENTRYPOINT ["/entrypoint"]
COPY ./dev/command.sh ./
RUN chmod +x command.sh
CMD ["./command.sh"]

# Development Image

FROM base AS dev

ENV ENABLE_LOCAL_HTTPS=1

# Testing Image

FROM base AS tests

# Production Image

FROM base AS prod

# Add appuser
RUN adduser --system --no-create-home appuser && \
    chown appuser /app/ && \
    chown appuser /etc/caddy/ && \
    chown appuser /config/caddy/

USER appuser
