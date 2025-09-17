.PHONY: all install build test build-docker run-docker stop-docker restart-docker publish-docker

all: install build test build-docker

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64

install:
	NODE_OPTIONS=--openssl-legacy-provider npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

run-devserver:
	# This will start a local dev server that runs the unminified frontend, outside of Docker. This can be useful
	# during active development, so images don't need to be rebuilt to validate each change.
	NODE_OPTIONS=--openssl-legacy-provider npm run start

test:
	NODE_OPTIONS=--openssl-legacy-provider npm run test

build-docker:
	docker buildx build -t helium/frontend:$(PLATFORM)-latest -t helium/frontend:$(PLATFORM)-$(TAG_VERSION) --platform=linux/$(PLATFORM) --load .

run-docker:
	docker compose up -d

stop-docker:
	docker compose stop

restart-docker: stop-docker run-docker

publish-docker: build-docker
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/heliumedu

	docker tag helium/frontend:$(PLATFORM)-$(TAG_VERSION) public.ecr.aws/heliumedu/helium/frontend:$(PLATFORM)-$(TAG_VERSION)
	docker push public.ecr.aws/heliumedu/helium/frontend:$(PLATFORM)-$(TAG_VERSION)