#!/bin/bash

# Set directory paths
CERT_DIR="/opt/stackql/srv/credentials"

# Function to fetch a secret from Azure Key Vault
fetch_secret() {
    local secret_name=$1
    local secret_value=$(curl -s \
                            -H "Authorization: Bearer $KEYVAULT_CREDENTIAL" \
                            "https://$KEYVAULT_NAME.vault.azure.net/secrets/$secret_name?api-version=7.0" | jq -r '.value')

    if [ -z "$secret_value" ]; then
        echo "Failed to fetch secret: $secret_name"
        exit 1
    fi

    echo "$secret_value"
}

# Write secrets to files
write_cert_or_key() {
    local content=$1
    local file_path=$2

    echo "$content" > "$file_path"
    chmod 600 "$file_path"
}

# Check if certificates and keys are present in the directory
check_certs_and_keys() {
    local server_cert="$CERT_DIR/pg_server_cert.pem"
    local server_key="$CERT_DIR/pg_server_key.pem"
    local client_cert="$CERT_DIR/pg_client_cert.pem"

    if [ ! -f "$server_cert" ] || [ ! -f "$server_key" ] || [ ! -f "$client_cert" ]; then
        echo "Certificates or keys are missing in $CERT_DIR"
        exit 1
    fi

    # Set permissions for the certificates and keys
    chmod 600 "$server_cert" "$server_key" "$client_cert"
}

# Fetch and write secrets if needed
fetch_and_write_secrets() {
    echo "Fetching secrets from Azure Key Vault..."
    local server_cert=$(fetch_secret "pg_server_cert")
    local server_key=$(fetch_secret "pg_server_key")
    local client_cert=$(fetch_secret "pg_client_cert")

    write_cert_or_key "$server_cert" "$CERT_DIR/pg_server_cert.pem"
    write_cert_or_key "$server_key" "$CERT_DIR/pg_server_key.pem"
    write_cert_or_key "$client_cert" "$CERT_DIR/pg_client_cert.pem"

    echo "Secrets fetched and written to $CERT_DIR"
}

# Function to start StackQL with or without mTLS
start_stackql() {
    if [ "$SECURE_MODE" = "true" ]; then
        echo "Running with mTLS..."

        # Fetch secrets from Azure Key Vault if not running locally
        if [ "$KEYVAULT_NAME" != "local" ] && [ "$KEYVAULT_CREDENTIAL" != "notset" ]; then
            fetch_and_write_secrets
        else
            echo "Using local secrets..."
        fi

        # Check if certificates and keys are present and set their permissions
        check_certs_and_keys

        CLIENT_CA_ENCODED=$(base64 -w 0 "$CERT_DIR/pg_client_cert.pem")

        # Start the server with TLS configuration
        /srv/stackql/stackql srv --approot=/srv/stackql/.stackql \
        --pgsrv.port=$PGSRV_PORT \
        --sqlBackend="{\"dbEngine\": \"postgres_tcp\", \"sqlDialect\": \"postgres\", \"dsn\": \"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}\"}" \
        --pgsrv.tls="{ \
            \"keyFilePath\": \"$CERT_DIR/pg_server_key.pem\", \
            \"certFilePath\": \"$CERT_DIR/pg_server_cert.pem\", \
            \"clientCAs\": [\"$CLIENT_CA_ENCODED\"] \
        }"
    else
        # Start the server without TLS configuration
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
