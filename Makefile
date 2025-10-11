.PHONY: all install install-dev run-devserver clean clean-assets build build-dev test build-docker run-docker stop-docker restart-docker publish-docker

all: test build-docker run-docker

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64
ENVIRONMENT ?= prod

install:
	NODE_ENV=production npm install

install-dev:
	npm install

clean-assets:
	rm -rf build

clean: clean-assets
	rm -rf node_modules

build: clean-assets install
	npm run build

build-dev: clean-assets install-dev
	npm run build-dev

run-devserver: clean-assets install-dev
	# This will start a local dev server that runs the unminified frontend, outside of Docker. This can be useful
	# during active development, so container images don't need to be rebuilt to validate each change.
	npm start

test: build-dev
	npm run test

build-docker:
	docker buildx build --build-arg ENVIRONMENT=$(ENVIRONMENT) --secret id=frontend_rollbar_client_item_access_token,env=FRONTEND_ROLLBAR_CLIENT_ITEM_ACCESS_TOKEN -t helium/frontend:$(PLATFORM)-latest -t helium/frontend:$(PLATFORM)-$(TAG_VERSION) --platform=linux/$(PLATFORM) --load .

run-docker:
	docker compose up -d

stop-docker:
	docker compose stop

restart-docker: stop-docker run-docker

publish-docker: build-docker
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/heliumedu

	docker tag helium/frontend:$(PLATFORM)-$(TAG_VERSION) public.ecr.aws/heliumedu/helium/frontend:$(PLATFORM)-$(TAG_VERSION)
	docker push public.ecr.aws/heliumedu/helium/frontend:$(PLATFORM)-$(TAG_VERSION)

	docker create --name frontend helium/frontend:$(PLATFORM)-$(TAG_VERSION)
	docker cp frontend:/app build
	aws s3 sync build "s3://heliumedu/helium/frontend/$(TAG_VERSION)"
