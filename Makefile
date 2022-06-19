SHELL := /usr/bin/env bash

# Export variables from .env file
include .env
$(eval export $(shell sed -ne 's/ *#.*$$//; /./ s/=.*$$// p' .env))

.DEFAULT_GOAL := help

.PHONY: help run test docker-build 
.PHONY: db-up db-gen db-migrate-up db-migrate-down db-migrate-create

DB_CONTAINER_NAME := pg
# Filter out make goals from CLI args
args = $(filter-out $@,$(MAKECMDGOALS))

# Do nothing if target not found
%:
	@:

help: ## print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

run: ## start development server
	go run cmd/main.go

test: ## run all tests. usage: make test or make test <dir>
	go test ./$(or $(args), ...) -v --race

docker-build: ## build docker image
	@docker build -t ${NAME}:${VERSION} .

db-up: db-run db-migrate-up
	@echo "migrations ready"

db-run: ## run postgres DB in docker container
	@docker run --name ${DB_CONTAINER_NAME} -p 5432:5432 \
		-e POSTGRES_HOST_AUTH_METHOD=trust \
		-d postgres:12-alpine
	@while ! docker exec ${DB_CONTAINER_NAME} pg_isready -U enc -d encryption -q; do echo "waiting for postgres"; sleep 1; done
	@echo "postgres ready"

db-migrate-up: ## run DB migrations
	@docker run \
		-v ${CURDIR}/db/migrations:/migrations \
		--network host migrate/migrate \
    -path=/migrations/ -database "$(DB_SOURCE)" -verbose up

db-migrate-down: ## down DB migrations
	@docker run \
		-v ${CURDIR}/db/migrations:/migrations \
		--network host \
		migrate/migrate \
		-path=/migrations/ -database "$(DB_SOURCE)" -verbose down -all

db-migrate-create: ## create DB migration. usage: make db-migrate-create <name>
	@docker run \
		-v ${CURDIR}/db/migrations:/migrations \
		migrate/migrate \
		create -ext sql -dir /migrations $(args)

db/schema.sql: db/schema.dbml
	dbml2sql db/schema.dbml -o db/schema.sql --postgres

pkg/db/%.go: db/queries/%.sql
	@docker run --rm -v ${CURDIR}:/src -w /src kjconroy/sqlc generate

