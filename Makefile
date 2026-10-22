COMPOSE := docker compose

.PHONY: up down reset logs

## up: build and start Lucee + MySQL, wait until both are healthy
up:
	$(COMPOSE) up -d --build --wait

## down: stop containers (database volume is kept)
down:
	$(COMPOSE) down

## reset: wipe the database volume and reload db/ scripts from scratch
reset:
	$(COMPOSE) rm --stop --force db
	docker volume rm --force stortrak_mysql-data
	$(COMPOSE) up -d --wait db
	$(COMPOSE) restart app

## logs: follow logs from all services
logs:
	$(COMPOSE) logs -f --tail=200
