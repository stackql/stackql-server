#!/bin/bash
set -e

# Grant privileges to the 'stackql' user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE stackql TO stackql;
EOSQL
