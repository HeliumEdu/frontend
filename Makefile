.PHONY: all env install clean build test

SHELL := /usr/bin/env bash

all: test

env:
	cp -n .env.example .env | true

	@if [[ -z "${ANDROID_GOOGLE_SERVICES_JSON}" ]] || \
		[[ -z "${IOS_GOOGLE_SERVICES_PLIST}" ]]; then \
		echo "Error: ANDROID_GOOGLE_SERVICES_JSON and IOS_GOOGLE_SERVICES_PLIST environment variables are required."; \
		exit 1; \
	fi

	echo "$${ANDROID_GOOGLE_SERVICES_JSON}" > android/app/google-services.json
	echo "$${IOS_GOOGLE_SERVICES_PLIST}" > ios/Runner/GoogleService-Info.plist

install: env
	flutter pub get

clean:
	flutter clean

build: install
	flutter build apk --release

test: install
	flutter test
