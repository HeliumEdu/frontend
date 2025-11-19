.PHONY: all env install clean build test

SHELL := /usr/bin/env bash

all: test

env:
	@if [[ -z "$${ANDROID_GOOGLE_SERVICES_JSON}" ]] || \
		[[ -z "$${IOS_GOOGLE_SERVICES_PLIST}" ]]; then \
		echo "Set all env vars required: [\
ANDROID_GOOGLE_SERVICES_JSON, \
IOS_GOOGLE_SERVICES_PLIST]"; \
		exit 1; \
	fi

	cp -n .env.example .env | true

	echo "$${ANDROID_GOOGLE_SERVICES_JSON}" > android/app/google-services.json
	echo "$${IOS_GOOGLE_SERVICES_PLIST}" > ios/Runner/GoogleService-Info.plist

install: env
	flutter pub get

clean:
	flutter clean

build-android: install
	flutter build apk

build-ios: install
	flutter build ios

test: install
	flutter test
