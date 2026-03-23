# Detecta automaticamente a arquitetura da máquina atual
ARCH := $(shell uname -m)

ifeq ($(ARCH), arm64)
  COMPOSE_OVERRIDE = -f docker-compose.yml -f docker-compose.arm64.yml
else
  COMPOSE_OVERRIDE = -f docker-compose.yml -f docker-compose.x86.yml
endif

COMPOSE = docker compose $(COMPOSE_OVERRIDE)

.PHONY: up down build logs shell migrate fresh seed test key ps

# Detecta e sobe para a arquitetura correta automaticamente
up:
	@echo "Arquitetura detectada: $(ARCH)"
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build --no-cache

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

shell:
	$(COMPOSE) exec backend sh

migrate:
	$(COMPOSE) exec backend php artisan migrate

fresh:
	$(COMPOSE) exec backend php artisan migrate:fresh --seed

seed:
	$(COMPOSE) exec backend php artisan db:seed

test:
	$(COMPOSE) exec backend php artisan test

key:
	$(COMPOSE) exec backend php artisan key:generate

# Sobe explicitamente para ARM64
up-arm:
	docker compose -f docker-compose.yml -f docker-compose.arm64.yml up -d

# Sobe explicitamente para x86_64
up-x86:
	docker compose -f docker-compose.yml -f docker-compose.x86.yml up -d
