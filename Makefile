.PHONY: all env install build test

all: env install build migrate test

env:
	cp -n .env.example .env | true

install: env
	npm install

build:
	CI=true npm run build

test:
	CI=true npm run test
