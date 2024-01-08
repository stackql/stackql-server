# Use postgres image
FROM postgres:latest

# Environment variables for postgres backend
ENV POSTGRES_HOST=127.0.0.1
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=stackql
ENV POSTGRES_PASSWORD=stackql
ENV POSTGRES_DB=stackql

# Environment variable to toggle SECURE_MODE
ENV SECURE_MODE=false

# Environment variable for StackQL server configuration
ENV PGSRV_PORT=7432

# Copy initialization script for database
COPY ./init-db.sh /docker-entrypoint-initdb.d/init-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Install certificates
RUN apt-get update && \
    apt-get install -y curl jq ca-certificates && update-ca-certificates

# Expose port
EXPOSE $PGSRV_PORT

# Volume for certificates
VOLUME ["/opt/stackql/srv/credentials"]

# Copy the StackQL binary and startup script
COPY --from=stackql/stackql:latest /srv/stackql/stackql /srv/stackql/stackql
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Set the startup script as the entrypoint
ENTRYPOINT ["/usr/local/bin/startup.sh"]
