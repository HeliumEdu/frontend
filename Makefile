.PHONY: all env install build migrate test

all: env install build migrate test

env:
	cp -n .env.example .env | true

install: env
	npm install

build:
	npm run build

migrate:
	echo "Nothing to migrate."

test:
	npm run test
