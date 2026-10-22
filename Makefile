COMPOSE := docker compose

.PHONY: up down reset logs

## up: build and start Lucee + MySQL, wait until both are healthy
up:
	$(COMPOSE) up -d --build --wait

## down: stop containers (database volume is kept)
down:
	$(COMPOSE) down

# Run a shell command in the db container. The root password and database
# name come from the container's own environment (see docker-compose.yml),
# so they are not duplicated here. MYSQL_PWD avoids the password-on-CLI warning.
DB_SH := $(COMPOSE) exec -T db sh -c

## reset: drop and recreate the database, then load db/schema.sql
reset:
	$(COMPOSE) up -d --wait db
	$(DB_SH) 'MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" mysql -uroot -e "DROP DATABASE IF EXISTS $$MYSQL_DATABASE; CREATE DATABASE $$MYSQL_DATABASE;"'
	$(DB_SH) 'MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" mysql -uroot "$$MYSQL_DATABASE"' < db/schema.sql
	@echo "Database reset; schema loaded."

## logs: follow logs from all services
logs:
	$(COMPOSE) logs -f --tail=200
