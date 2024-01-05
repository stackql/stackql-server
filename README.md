# StackQL Server with PostgreSQL Backend

# Table of Contents

1. [Architecture](#architecture)
   - [StackQL Server](#stackql-server)
   - [PostgreSQL Server](#postgresql-server)
2. [Deployment Options](#deployment-options)
3. [Authenticating to Cloud Providers](#authenticating-to-cloud-providers)
4. [Building and Running the Container](#building-and-running-the-container)
   - [Without mTLS (`SECURE_MODE=false`)](#without-mtls-secure_modefalse)
     - [Building and Running Locally](#building-and-running-locally)
     - [Stopping the Container](#stopping-the-container)
     - [Running from Dockerhub Image](#running-from-dockerhub-image)
     - [Connecting to the Server](#connecting-to-the-server)
   - [With mTLS (`SECURE_MODE=true`)](#with-mtls-secure_modetrue)
     - [Preparing Certificates and Keys](#preparing-certificates-and-keys)
     - [Building and Running Locally](#building-and-running-locally-1)
     - [Running Using Dockerhub Image](#running-using-dockerhub-image)
     - [Connecting to the Server](#connecting-to-the-server-1)
5. [Running the Container in Azure Container Instances (ACI)](#running-the-container-in-azure-container-instances-aci)
   - [Push Image to Azure Container Registry (ACR)](#push-image-to-azure-container-registry-acr)
   - [Start ACI Container](#start-aci-container)
   - [Set Secrets in Azure Key Vault (AKV)](#set-secrets-in-azure-key-vault-akv)
   - [Retrieve Certificates using KEYVAULT_NAME and KEYVAULT_CREDENTIAL](#retrieve-certificates-using-keyvault_name-and-keyvault_credential)
   - [Getting Fully Qualified Domain Name (FQDN) of the ACI](#getting-fully-qualified-domain-name-fqdn-of-the-aci)
   - [Connecting to the Server](#connecting-to-the-server-2)

## Architecture

The architecture consists of two primary components:

1. **StackQL Server**: A server that starts a [StackQL](https://github.com/stackql/stackql) server, accepting StackQL queries using the PostgreSQL wire protocol.
2. **PostgreSQL Server**: A backend database server used for relational algebra and temporary storage, particularly for materialized views.

```mermaid
graph TD;
    subgraph Docker_or_ACI["Docker or Azure Container Instances (ACI)"];
        B[StackQL Server];
        C["Local PostgreSQL Instance\n(if POSTGRES_HOST == 127.0.0.1)"];
        B <-- uses --> C;
    end;
    A[StackQL Client] <-- PostgreSQL wire protocol port 7432\n(SECURE_MODE uses mTLS) --> B;
    B <-- gets data from\nor interacts with --> E[Cloud/SaaS Providers];
    KV[Azure Key Vault] -.->|"Stores Secrets\nfor SECURE_MODE\n(if KEYVAULT_NAME && KEYVAULT_CREDENTIAL)"| B;

    %% Positioning the remote DB at the bottom
    B <-.->|if POSTGRES_HOST != 127.0.0.1| RemoteDB["Remote PostgreSQL Database"];
```

## Deployment Options

The different deployment options are as follows:

### Local DB Mode

`stackql-server` can be deployed with a local embedded Postgres DB backend.  This can be used with mTLS configured (using `SECURE_MODE=true`) or without mTLS (`SECURE_MODE=false`).  Server certificates and keys can be copied into the container or fetched from a remote location (if `KEYVAULT_NAME` && `KEYVAULT_CREDENTIAL` are supplied).

### Remote DB Mode

If `POSTGRES_HOST` is set to a value other than `127.0.0.1` a remote DB connection will be used for the relational algebra backend.  This can be used with mTLS configured (using `SECURE_MODE=true`) or without mTLS (`SECURE_MODE=false`).  Server certificates and keys can be copied into the container or fetched from a remote location (if `KEYVAULT_NAME` && `KEYVAULT_CREDENTIAL` are supplied).



## Authenticating to Cloud Providers

Populate the necessary environment variables to authenticate with your specific cloud providers. For more information on which environment variables to populate, see the [StackQL provider registry](https://github.com/stackql/stackql-provider-registry) documentation.

## Building and Running the Container

### Without mTLS (`SECURE_MODE=false`)

**To build and run locally:**
```bash
docker build --no-cache -t stackql-server .
# Use -e to supply provider credentials as needed (GitHub credentials used in this example)
docker run -d -p 7432:7432 \
-e STACKQL_GITHUB_USERNAME \
-e STACKQL_GITHUB_PASSWORD \
stackql-server
```

**To stop the container:**
```bash
docker stop $(docker ps -a -q --filter ancestor=stackql-server --format="{{.ID}}")
```

**To run from the Dockerhub image:**
```bash
# Use -e to supply provider credentials as needed (GitHub credentials used in this example)
docker run -d -p 7432:7432 \
-e STACKQL_GITHUB_USERNAME \
-e STACKQL_GITHUB_PASSWORD \
stackql/stackql-server
```

**To stop the container:**
```bash
docker stop $(docker ps -a -q --filter ancestor=stackql/stackql-server --format="{{.ID}}")
```

**Connecting to the server:**
```bash
psql -h localhost -p 7432 -U stackql -d stackql
```

### With mTLS (`SECURE_MODE=true`)

**To prepare certificates and keys:**
```bash
# Follow these steps to generate Root CA, Server Cert, and Client Cert
[Instructions for certificate generation here]
```

**To build and run locally:**
```bash
docker build --no-cache -t stackql-server .
# Use -e to supply provider credentials as needed (GitHub credentials used in this example)
docker run -d -p 7432:7432 \
-e STACKQL_GITHUB_USERNAME \
-e STACKQL_GITHUB_PASSWORD \
-e SECURE_MODE=true -v $(pwd)/creds:/opt/stackql/srv/credentials \
stackql-server
```

**Or using Dockerhub image:**
```bash
# Use -e to supply provider credentials as needed (GitHub credentials used in this example)
docker run -d -p 7432:7432 \
-e STACKQL_GITHUB_USERNAME \
-e STACKQL_GITHUB_PASSWORD \
-e SECURE_MODE=true -v $(pwd)/creds:/opt/stackql/srv/credentials \
stackql/stackql-server
```

**Connect to the server:**
```bash
psql "sslmode=verify-ca sslrootcert=creds/ca.crt \
sslcert=creds/client.crt sslkey=creds/client.key \
host=localhost port=7432 user=stackql dbname=stackql"
```

## Running the Container in Azure Container Instances (ACI)

### Steps to deploy:

1. **Push Image to Azure Container Registry (ACR):**
   - [Instructions for pushing image to ACR]
2. **Start ACI Container:**
   - [Instructions to start ACI container]
3. **Set Secrets in Azure Key Vault (AKV):**
   - [Instructions to set secrets in AKV]
4. **Use KEYVAULT_NAME and KEYVAULT_CREDENTIAL to Retrieve Certificates:**
   - [Instructions for retrieving certs using Key Vault credentials]
5. **Get Fully Qualified Domain Name (FQDN) of the ACI:**
   - [Instructions to get FQDN]
6. **Connect to the Server:**
   - [Instructions for server connection]
