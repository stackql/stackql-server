# StackQL Server with PostgreSQL Backend

## Architecture

The architecture involves two primary components:

1. **StackQL Server**: This server starts a [__`stackql`__](https://github.com/stackql/stackql) server accepting stackql queries using the PostgreSQL wire protocol.
2. **PostgreSQL Server**: Backend database server used for relational algebra and temporary storage (for materalized views).

```mermaid
graph TD;
    subgraph Container;
        B[StackQL Server];
        C[PostgreSQL Instance];
    end;
    A[StackQL Client] <-- postgre wire protocol port 7432 --> B;
    B <-- gets data from --> E[Cloud/SaaS Providers];
    B <-- uses --> C;
```

## Running the Container from the DockerHub Image

To run the container, execute the following command:

```bash
docker run -d -p 7432:7432 stackql/stackql-server
```

## Building and Running the Container

To run the container, execute the following command:

```bash
docker build --no-cache -t stackql-server .
docker run -d -p 7432:7432 stackql-server
```

## Submitting a Query to the StackQL Server

To submit a query to the StackQL server using `psql`, use the following command:

```bash
psql -h localhost -p 7432 -U stackql -d stackql
```

