.PHONY: all install build test build-docker run-docker stop-docker publish-docker

all: install build test build-docker

SHELL := /usr/bin/env bash
AWS_REGION ?= us-east-1
TAG_VERSION ?= latest
PLATFORM ?= linux/arm64

install:
	@npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

test:
	@npm run test

build-docker:
	docker buildx build -t helium/frontend:latest -t helium/frontend:$(TAG_VERSION) --platform=$(PLATFORM) --load .

run-docker:
	docker compose up -d

stop-docker:
	docker compose stop

publish-docker: build-docker
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com
	docker tag helium/frontend:$(TAG_VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(TAG_VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/helium/frontend:$(TAG_VERSION)