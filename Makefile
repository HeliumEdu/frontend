.PHONY: all install clean run-devserver test build-docker run-docker stop-docker restart-docker publish-docker

all: test build-docker run-docker

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64

install:
	NODE_OPTIONS=--openssl-legacy-provider npm install

clean:
	rm -rf node_modules build src/assets/js/*.min.js

run-devserver: install
	# This will start a local dev server that runs the unminified frontend, outside of Docker. This can be useful
	# during active development, so images don't need to be rebuilt to validate each change.
	NODE_OPTIONS=--openssl-legacy-provider npm run start

test: install
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