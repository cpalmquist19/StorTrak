COMPOSE := docker compose

.PHONY: up down seed reset check logs

## up: build and start Lucee + MySQL, wait until both are healthy
up:
	$(COMPOSE) up -d --build --wait

## down: stop containers (database volume is kept)
down:
	$(COMPOSE) down

# Helper on the db container's PATH (docker/db/stortrak-db.sh). It reads the root
# password and database name from the container's environment and keeps shell
# quoting and absolute paths out of these recipes, so they run unchanged under sh,
# cmd.exe, and Git Bash (which would rewrite a "/path" argument into a Windows path).
DB_TOOL := $(COMPOSE) exec -T db stortrak-db

## seed: regenerate db/seed.sql (deterministic; see seed/README.md)
seed:
	$(COMPOSE) run --rm --build seed

## reset: regenerate the seed, drop and recreate the database, load schema + seed
reset: seed
	$(COMPOSE) up -d --wait db
	$(DB_TOOL) recreate
	$(DB_TOOL) load < db/schema.sql
	$(DB_TOOL) load < db/seed.sql
	@echo Database reset: schema and seed loaded.

## check: print table row counts and the seed summary from the database
check:
	$(COMPOSE) up -d --wait db
	$(DB_TOOL) query < db/check.sql

## logs: follow logs from all services
logs:
	$(COMPOSE) logs -f --tail=200
