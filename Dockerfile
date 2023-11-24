FROM stackql/stackql:latest as stackql

FROM postgres:latest as postgres
ENV POSTGRES_USER=stackql
ENV POSTGRES_PASSWORD=stackql
ENV POSTGRES_DB=stackql
COPY ./init-db.sh /docker-entrypoint-initdb.d/init-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh
COPY --from=stackql /srv/stackql/stackql /srv/stackql/stackql
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates
EXPOSE 7432

# Environment variables for StackQL server
ENV PGSRV_PORT=7432
ENV SQL_BACKEND_JSON='{"dbEngine": "postgres_tcp", "sqlDialect": "postgres", "dsn": "postgres://stackql:stackql@127.0.0.1:5432/stackql"}'

# Start both PostgreSQL and StackQL server
CMD ["sh", "-c", "/usr/local/bin/docker-entrypoint.sh postgres & /srv/stackql/stackql srv --approot=/srv/stackql/.stackql --pgsrv.port=$PGSRV_PORT --sqlBackend='{\"dbEngine\": \"postgres_tcp\", \"sqlDialect\": \"postgres\", \"dsn\": \"postgres://stackql:stackql@127.0.0.1:5432/stackql\"}'"]