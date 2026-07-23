#!/bin/sh
# Co-authored-by: Claude <noreply@anthropic.com>

set -ae

# Define variables and set defaults where applicable
TRAEFIK_CONFIG="${TRAEFIK_CONFIG:-/etc/traefik/traefik.yml}"
TRAEFIK_LOG_LEVEL="${TRAEFIK_LOG_LEVEL:-INFO}"
ENABLE_DASHBOARD="${ENABLE_DASHBOARD:-}"
DYNAMIC_DIR="${DYNAMIC_DIR:-/etc/traefik/dynamic}"
DYNAMIC_CONFIG="${DYNAMIC_DIR}/dynamic.yml"
SERVICES_DIR="${SERVICES_DIR:-/services}"
ENABLE_LOCAL_HTTPS="${ENABLE_LOCAL_HTTPS:-}"
HTTPS_CERT_FILE="${HTTPS_CERT_FILE:-/certs/cert.pem}"
HTTPS_KEY_FILE="${HTTPS_KEY_FILE:-/certs/key.pem}"
ENABLE_AUTO_HTTPS="${ENABLE_AUTO_HTTPS:-}"
EXTERNAL_ADDRESS="${EXTERNAL_ADDRESS:-openslides.example.com}"
EXTERNAL_ADDRESS_IDP="${EXTERNAL_ADDRESS_IDP:-https://localhost:8800}"
ACME_ENDPOINT="${ACME_ENDPOINT:-}"
ACME_EMAIL="${ACME_EMAIL:-}"

# Set default values for service endpoints
ACTION_HOST="${ACTION_HOST:-backend}"
ACTION_PORT="${ACTION_PORT:-9002}"
PRESENTER_HOST="${PRESENTER_HOST:-backend}"
PRESENTER_PORT="${PRESENTER_PORT:-9003}"
AUTOUPDATE_HOST="${AUTOUPDATE_HOST:-autoupdate}"
AUTOUPDATE_PORT="${AUTOUPDATE_PORT:-9012}"
ICC_HOST="${ICC_HOST:-icc}"
ICC_PORT="${ICC_PORT:-9007}"
AUTH_HOST="${AUTH_HOST:-auth}"
AUTH_PORT="${AUTH_PORT:-9004}"
SEARCH_HOST="${SEARCH_HOST:-search}"
SEARCH_PORT="${SEARCH_PORT:-9050}"
PROJECTOR_HOST="${PROJECTOR_HOST:-projector}"
PROJECTOR_PORT="${PROJECTOR_PORT:-9051}"
MEDIA_HOST="${MEDIA_HOST:-media}"
MEDIA_PORT="${MEDIA_PORT:-9006}"
MANAGE_HOST="${MANAGE_HOST:-manage}"
MANAGE_PORT="${MANAGE_PORT:-9008}"
IDENTITY_HOST="${IDENTITY_HOST:-identity}"
IDENTITY_PORT="${IDENTITY_PORT:-9014}"
VOTE_HOST="${VOTE_HOST:-vote}"
VOTE_PORT="${VOTE_PORT:-9013}"
CLIENT_HOST="${CLIENT_HOST:-client}"
CLIENT_PORT="${CLIENT_PORT:-9001}"
IDP_HOST="${IDP_HOST:-zitadel-api}"
IDP_HOST_PORT="${IDP_HOST_PORT:-8080}"
IDP_LOGIN_HOST="${IDP_LOGIN_HOST:-zitadel-login}"
IDP_LOGIN_HOST_PORT="${IDP_LOGIN_HOST_PORT:-3000}"
INSTANCE_URL="${INSTANCE_URL:-https://localhost:8000}"
IDP_URL_EXTERNAL="${IDP_URL_EXTERNAL:-https://localhost:8800}"
IDP_URL_INTERNAL="${IDP_URL_INTERNAL:-h2c://zitadel-api:8080}"


# =================================
# = Build static / install config =
# =================================

# Get Zitadel Client ID
IDP_PAT="$(cat /zitadel/bootstrap/admin.pat)"
IDP_CLIENT_ID="$(cat /zitadel/bootstrap/client-id)"
# IDP_CLIENT_SECRET="$(cat /zitadel/bootstrap/client-secret)"

# echo $IDP_PAT

# Import Data

#PAYLOAD=$(cat <<EOF
#{
#  "timeout" : "5m",
#  "dataOrgs": $(cat /import-data.json)
#}
#EOF
#)

#echo $PAYLOAD

#RESPONSE=$(curl -X POST "$IDP_API_URL/admin/v1/import" \
#  --header "Authorization: Bearer ${IDP_PAT}" \
#  --header "Content-Type: application/json"\
#  --header "Host: ${INSTANCE_URL}" \
#  --data "${PAYLOAD}")

#echo $PAYLOAD

#IDP_APP_INFORMATION=$(curl -sS -X POST \
#  "${IDP_API_URL}/zitadel.application.v2.ApplicationService/ListApplications" \
#  -H "Authorization: Bearer $IDP_PAT" \
#  -H "Content-Type: application/json" \
#  -H "Host: ${INSTANCE_URL}" \
#  -d '{}')

#IDP_CLIENT_ID="$(echo $IDP_APP_INFORMATION | jq -r '.applications[0].oidcConfiguration.clientId')"
#IDP_PROJECT_ID="$(echo $IDP_APP_INFORMATION | jq -r '.applications[0].projectId')"
#IDP_APPLICATION_ID="$(echo $IDP_APP_INFORMATION | jq -r '.applications[0].applicationId')"

#echo "CLIENT ID: --- $IDP_CLIENT_ID"
#echo "Project ID: --- $IDP_PROJECT_ID"
#echo "App ID: --- $IDP_APPLICATION_ID"

#if [ "$IDP_CLIENT_ID" == "null" ]
#then
#  echo "No client ID has been returned by zitadel"
#  echo "Response: $RESPONSE"
#  sleep infinity
#fi

#IDP_CLIENT_SECRET=$(curl -sS -X POST \
#  "${IDP_API_URL}/zitadel.application.v2.ApplicationService/GenerateClientSecret" \
#  -H "Host:  ${INSTANCE_URL}" \
#  -H "Authorization: Bearer $IDP_PAT" \
#  -H "Content-Type: application/json" \
#  -H "Connect-Protocol-Version: 1" \
#  -d '{
#    \"projectId\": \"$IDP_PROJECT_ID\",
#    \"applicationId\": \"$IDP_APPLICATION_ID\"
#  }' \
#| jq -r '.clientSecret')

#echo "CLIENT SECRET: --- $IDP_CLIENT_SECRET"

# Generate base config from template
envsubst < /templates/traefik.yml > "$TRAEFIK_CONFIG"

# Add OIDC plugin
echo "Adding OIDC Plugin"
cat >> "$TRAEFIK_CONFIG" << 'EOF'

experimental:
  plugins:
    traefik-oidc-auth:
      moduleName: github.com/sevensolutions/traefik-oidc-auth
      version: v0.20.0
  localPlugins:
    user_id_header:
      moduleName: github.com/openslides/user_id_header
EOF


# Add dashboard if enabled
if [ -n "$ENABLE_DASHBOARD" ]; then
  echo "Enabling dashboard. 'debug: true' for now. NOT FOR PRODUCTION"
  cat >> "$TRAEFIK_CONFIG" << 'EOF'

api:
  dashboard: true
  debug: true
EOF
fi

# Add entryPoints in accordance to HTTPS related variables
cat >> "$TRAEFIK_CONFIG" << 'EOF'
entryPoints:
  main:
    address: ":8000"
    http:
EOF

if [ -n "$ENABLE_LOCAL_HTTPS" ]; then
  # Define tls property, which will cause all routers to terminate TLS and
  # foward decrypted traffic.
  cat >> "$TRAEFIK_CONFIG" << 'EOF'
      tls: {}
EOF
elif [ -n "$ENABLE_AUTO_HTTPS" ]; then
  # Also needs tls property, but with additional information for cert retrieval
  cat >> "$TRAEFIK_CONFIG" << EOF
      tls:
        domains:
          - main: ${EXTERNAL_ADDRESS}
        certResolver: acmeResolver
EOF
fi

# Add entryPoints in accordance to HTTPS related variables
cat >> "$TRAEFIK_CONFIG" << 'EOF'
  idp:
    address: ":8800"
    http:
EOF

if [ -n "$ENABLE_LOCAL_HTTPS" ]; then
  # Define tls property, which will cause all routers to terminate TLS and
  # foward decrypted traffic.
  cat >> "$TRAEFIK_CONFIG" << 'EOF'
      tls: {}
EOF
elif [ -n "$ENABLE_AUTO_HTTPS" ]; then
  # Also needs tls property, but with additional information for cert retrieval
  cat >> "$TRAEFIK_CONFIG" << EOF
      tls:
        domains:
          - idp: ${EXTERNAL_ADDRESS_IDP}
        certResolver: acmeResolver
EOF
  # Additionally a plain HTTP endpoint to answer ACME challenges on must be
  # configured
  cat >> "$TRAEFIK_CONFIG" << 'EOF'

  acme:
    address: ":8001"
EOF
  # Add the certificates resolver providing information for automatic ACME
  # based cert retrieval.
  cat >> "$TRAEFIK_CONFIG" << EOF

certificatesResolvers:
  acmeResolver:
    acme:
      email: ${ACME_EMAIL}
      storage: acme.json
      httpChallenge:
        entryPoint: acme
EOF
  if [ -n "$ACME_ENDPOINT" ]; then
    cat >> "$TRAEFIK_CONFIG" << EOF
      caServer: ${ACME_ENDPOINT}
EOF
  fi

  echo "traefik was configured to automatically retrieve a TLS certificates via acme."
  echo "Make sure incoming challange requests (to HOST:80/.well-known/acme-challenge/) reach this container on port 8001"
  echo "In most cases forwarding the hosts port 80 to containers port 8001 is enough."
fi


# ==================================
# = Build dynamic / routing config =
# ==================================

# Start with empty file
echo "" > "$DYNAMIC_CONFIG"

if [ -n "$ENABLE_LOCAL_HTTPS" ]; then
  if [ -f "$HTTPS_CERT_FILE" ] && [ -f "$HTTPS_KEY_FILE" ]; then
    envsubst < /templates/tls.yml >> "$DYNAMIC_CONFIG"
  else
    echo "ERROR: no local cert-files provided. Did you run make-localhost-cert.sh?"
    exit 1
  fi
fi

# First build SERVICES list (space separated) based on files present in
# services directory
SERVICES=
for service_file in $SERVICES_DIR/*.service; do
  service=$(basename $service_file .service)
  service_upper=$(echo "$service" | tr '[:lower:]' '[:upper:]')
  host_var="${service_upper}_HOST"

  if [[ ! -f "$SERVICES_DIR/$service.service" ]] || [[ ! -f "$SERVICES_DIR/$service.router" ]]; then
    echo "Skipping, config incomplete: $service"
    continue
  fi

  if eval [[ -n "\$${host_var}" ]]; then
    eval "echo \"Adding config: $service (host: \$${host_var})\"" >&2
    SERVICES="$SERVICES $service"
  else
    echo "Skipping, disabled in environment: $service"
  fi
done

# Write to config file
cat >> "$DYNAMIC_CONFIG" << 'EOF'

http:
  routers:
EOF

# Concatenate all enabled .router files
for service in $SERVICES; do
  envsubst < "$SERVICES_DIR/${service}.router" >> "$DYNAMIC_CONFIG"
done

# Add services section
cat >> "$DYNAMIC_CONFIG" << 'EOF'

  services:
EOF

# Concatenate all enabled .service files
for service in $SERVICES; do
  envsubst < "$SERVICES_DIR/${service}.service" >> "$DYNAMIC_CONFIG"
done

# OIDC Middleware
echo "Enabling OIDC authentication middleware"
  cat >> "$DYNAMIC_CONFIG" << EOF

  middlewares:
    zitadel-cors:
      headers:
        accessControlAllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
          - PATCH
        accessControlAllowHeaders:
          - Authorization
          - Content-Type
          - X-CSRF-Token
          - Accept
          - Origin
          - Link
          - X-User-ID
          - Cache-Control
        accessControlAllowOriginList:
          - "https://localhost:8000"
          - "https://localhost:8080"
        accessControlMaxAge: 600
        addVaryHeader: true
        accessControlAllowCredentials: true
    oidc-auth:
      plugin:
        traefik-oidc-auth:
          Secret: "GfhkqLMQvlTmb0P8a8uqT39vRHQGpw6D"
          LogLevel: DEBUG
          Provider:
            Url: "${IDP_EXTERNAL_HOST}"
            ClientId: "${IDP_CLIENT_ID}"
            UsePkce: true
            InsecureSkipVerify: true
            ValidateIssuer: true
            ValidIssuer: "${IDP_URL_EXTERNAL}"
          UnauthorizedBehavior: Forward
          BypassAuthenticationRule: "PathPrefix(\`/\`)"
          LoginUri: "/system/login"
          LogoutUri: "/system/logout"
          Headers:
            - Name: "Authorization"
              Value: "{{\`Bearer: {{ .accessToken }}\`}}"
              IncludeWhen: "Public"
          Scopes: ["openid", "profile", "email"]
          SessionCookie:
            HttpOnly: false
            SameSite: lax
            Secure: true
    user-id:
      plugin:
        user_id_header: {}
EOF

cat $DYNAMIC_CONFIG

# Finally start CMD
exec "$@"
