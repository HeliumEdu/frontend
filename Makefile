.PHONY: all install build test build-docker run-docker publish-docker

all: install build test build-docker

SHELL := /usr/bin/env bash
AWS_REGION ?= us-east-1
TAG_VERSION ?= latest

install:
	@npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

test:
	@npm run test

build-docker:
	docker build -t helium/frontend:latest -t helium/frontend:$(TAG_VERSION) .

run-docker:
	docker compose up -d

publish-docker:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com
	docker tag helium/frontend:$(TAG_VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(TAG_VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(TAG_VERSION)