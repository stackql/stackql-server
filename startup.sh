#!/bin/bash

# External volume directory
EXT_VOL_CERT_DIR="/opt/stackql/srv/credentials"
# Fallback local directory
LOCAL_CERT_DIR="/usr/local/certs"
# Directory to hold certificates
CERT_DIR=""

# Function to check and set the CERT_DIR
set_cert_dir() {
    # Check if external volume directory is accessible
    if [ -d "$EXT_VOL_CERT_DIR" ] && [ -w "$EXT_VOL_CERT_DIR" ]; then
        echo "Using external volume for certificates."
        CERT_DIR="$EXT_VOL_CERT_DIR"
    else
        echo "External volume is not accessible. Using local directory for certificates."
        # Create local directory if it does not exist
        mkdir -p "$LOCAL_CERT_DIR"
        CERT_DIR="$LOCAL_CERT_DIR"
    fi
}

# Check if certificates and keys are present in the environment variables or the directory
check_certs_and_keys() {
    local server_cert="$CERT_DIR/server_cert.pem"
    local server_key="$CERT_DIR/server_key.pem"
    local client_cert="$CERT_DIR/client_cert.pem"

    if [ -z "$SERVER_CERT" ] || [ -z "$SERVER_KEY" ] || [ -z "$CLIENT_CERT" ]; then
        if [ ! -f "$server_cert" ] || [ ! -f "$server_key" ] || [ ! -f "$client_cert" ]; then
            echo "Certificates or keys are missing."
            exit 1
        fi
    else
        echo "$SERVER_CERT" | base64 -d > "$server_cert"
        echo "$SERVER_KEY" | base64 -d > "$server_key"
        echo "$CLIENT_CERT" | base64 -d > "$client_cert"
    fi

    # Set permissions for the certificates and keys
    chmod 600 "$server_cert" "$server_key" "$client_cert"
}

# Function to start StackQL with or without mTLS
start_stackql() {
    if [ "$SECURE_MODE" = "true" ]; then
        echo "Running with mTLS..."
        set_cert_dir
        check_certs_and_keys
        CLIENT_CA_ENCODED=$(base64 -w 0 "$CERT_DIR/client_cert.pem")
        # Start the server with TLS configuration
        /srv/stackql/stackql srv --approot=/srv/stackql/.stackql \
        --pgsrv.port=$PGSRV_PORT \
        --sqlBackend="{\"dbEngine\": \"postgres_tcp\", \"sqlDialect\": \"postgres\", \"dsn\": \"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}\"}" \
        --pgsrv.tls="{ \
            \"keyFilePath\": \"$CERT_DIR/server_key.pem\", \
            \"certFilePath\": \"$CERT_DIR/server_cert.pem\", \
            \"clientCAs\": [\"$CLIENT_CA_ENCODED\"] \
        }"
    else
        echo "Running without mTLS..."
        /srv/stackql/stackql srv --approot=/srv/stackql/.stackql \
        --pgsrv.port=$PGSRV_PORT \
        --sqlBackend="{\"dbEngine\": \"postgres_tcp\", \"sqlDialect\": \"postgres\", \"dsn\": \"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}\"}"
    fi
}

# Start PostgreSQL if running locally
if [ "$POSTGRES_HOST" = "127.0.0.1" ]; then
    echo "Running in local mode..."
    /usr/local/bin/docker-entrypoint.sh postgres &
fi

# Start StackQL
start_stackql
