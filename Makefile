.PHONY: all env install clean build test

SHELL := /usr/bin/env bash

all: test

env:
	cp -n .env.example .env | true

install: env
	flutter pub get

clean:
	rm -rf build $(PLATFORM_VENV)

build: install
	flutter build apk --release

test: install
	flutter test
