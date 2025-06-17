.PHONY: all install build test build-docker run-docker stop-docker publish-docker

all: install build test build-docker

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64

install:
	@npm install

build:
	NODE_OPTIONS=--openssl-legacy-provider npm run build

test:
	@npm run test

build-docker:
	docker buildx build -t helium/frontend:$(PLATFORM)-latest -t helium/frontend:$(PLATFORM)-$(TAG_VERSION) --platform=linux/$(PLATFORM) --load .

run-docker:
	docker compose up -d

stop-docker:
	docker compose stop

restart-docker: stop-docker run-docker

publish-docker: build-docker
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/w6u3m4h5

	docker tag helium/frontend:$(PLATFORM)-$(TAG_VERSION) public.ecr.aws/w6u3m4h5/helium/frontend:$(PLATFORM)-$(TAG_VERSION)
	docker push public.ecr.aws/w6u3m4h5/helium/frontend:$(PLATFORM)-$(TAG_VERSION)