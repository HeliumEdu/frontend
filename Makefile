.PHONY: all install build migrate test build-docker run-docker

all: install build migrate test

SHELL := /usr/bin/env bash
AWS_REGION ?= us-east-1
TAG_VERSION ?= latest

install:
	@npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

migrate:
	echo "Nothing to migrate."

test:
	@npm run test

build-docker: install build
	docker build -t helium/frontend:latest -t helium/frontend:$(TAG_VERSION) .

run-docker:
	docker compose up -d

push-docker:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com
	docker tag helium/frontend:$(TAG_VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(TAG_VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(AWS_ACCOUNT_ID)