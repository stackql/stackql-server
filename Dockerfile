# Use stackql image
FROM stackql/stackql:latest as stackql

# Use postgres image
FROM postgres:latest as postgres

# Environment variables for postgres backend
ENV POSTGRES_HOST=127.0.0.1
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=stackql
ENV POSTGRES_PASSWORD=stackql
ENV POSTGRES_DB=stackql

# Environment variable to toggle SECURE_MODE
ENV SECURE_MODE=false

# Environment variable for Key Vault name for SECURE_MODE, if local use local cert and key files
ENV KEYVAULT_NAME=local
ENV KEYVAULT_CREDENTIAL=notset

# Environment variable for StackQL server configuration
ENV PGSRV_PORT=7432

# Copy initialization script for database
COPY ./init-db.sh /docker-entrypoint-initdb.d/init-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Copy stackql binary
COPY --from=stackql /srv/stackql/stackql /srv/stackql/stackql

# Install certificates

RUN apt-get update && \
    apt-get install -y curl jq ca-certificates && update-ca-certificates

# Expose port
EXPOSE $PGSRV_PORT

# Volume for certificates
VOLUME ["/opt/stackql/srv/credentials"]

# Copy the startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Set the startup script as the entrypoint
ENTRYPOINT ["/usr/local/bin/startup.sh"]