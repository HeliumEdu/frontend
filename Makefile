.PHONY: all env install clean build test

SHELL := /usr/bin/env bash

all: test

env:
	cp -n .env.example .env | true

	if [ -z "$GOOGLE_SERVICES_JSON" ]; then
	  echo "Error: GOOGLE_SERVICES_JSON environment variable is not set."
	  exit 1
	fi

	echo "$GOOGLE_SERVICES_JSON" > android/app/google-services.json

install: env
	flutter pub get

clean:
	rm -rf build $(PLATFORM_VENV)

build: install
	flutter build apk --release

test: install
	flutter test
