.PHONY: all install build migrate test build-docker run-docker

all: install build migrate test

install:
	@npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

migrate:
	echo "Nothing to migrate."

test:
	@npm run test

build-docker: install build
	docker build -t helium-frontend .
	docker tag helium-frontend:latest helium:frontend

run-docker:
	docker compose up -d