.PHONY: all env install install-ios clean build-android build-ios test

SHELL := /usr/bin/env bash

ifdef PROJECT_API_HOST
    RUN_ARGS := --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
else
    RUN_ARGS :=
endif

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

install-ios: env
	pod install --project-directory=ios

clean:
	flutter clean

build-android: install
	flutter build apk --release

build-ios: install install-ios
	flutter build ipa --release --no-codesign

test: install
	flutter analyze --no-fatal-infos --no-fatal-warnings
	flutter test

run: install
	flutter run $(RUN_ARGS)
