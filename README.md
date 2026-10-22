# StorTrak

> ⚠️ **Intentionally vulnerable. For local benchmarking only. Never deploy.**

StorTrak is the rental and billing system for **Piedmont Stor-All**, a fictional
self-storage company with three facilities. It is a deliberately legacy CFML application
used as a benchmark target for automated refactoring tools. All names and data are fictional.

## Requirements

- Docker Desktop (or Docker Engine) with Compose v2
- GNU Make (on Windows: `winget install ezwinports.make`, or run the `docker compose`
  commands from the `Makefile` directly)

## Setup

```sh
make up
```

The first run builds the app image (CommandBox + Lucee 5.4) and initializes MySQL; allow a
couple of minutes. `make up` returns once both containers report healthy.

Open <http://127.0.0.1:8080/>. The page should show **DB OK**, the MySQL server time, the
number of delinquent tenants and lien rows, and every table in the schema with its row count.

A fresh database volume loads `db/schema.sql` and then `db/seed.sql` automatically.

## Commands

| Command      | What it does |
|--------------|--------------|
| `make up`    | Build and start Lucee + MySQL, wait for health checks |
| `make down`  | Stop containers (database data is kept) |
| `make seed`  | Regenerate `db/seed.sql` (deterministic; see [seed/README.md](seed/README.md)) |
| `make reset` | Regenerate the seed, drop and recreate the database, load schema + seed |
| `make logs`  | Follow container logs |

## Services

| Service | Image | Address |
|---------|-------|---------|
| app     | `ortussolutions/commandbox:jre11-3.23.1`, Lucee `5.4.8+2` | http://127.0.0.1:8080 |
| db      | `mysql:8.4.13` | `127.0.0.1:3307` (user/pass/db: `stortrak`) |

Both ports are bound to localhost only. Defaults can be overridden with environment
variables or a `.env` file: `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`,
`MYSQL_HOST_PORT`, `LUCEE_ADMIN_PASSWORD`.

The `stortrak` datasource is defined in `.cfconfig.json` and loaded by CommandBox at startup.

## Layout

```
webroot/          CFML application (legacy — see CLAUDE.md)
db/               schema.sql (legacy — see CLAUDE.md) and generated seed.sql
seed/             seed data generator (Python + Faker)
docker/           container build files
server.json       CommandBox server config
.cfconfig.json    Lucee config (datasource, admin password)
```
