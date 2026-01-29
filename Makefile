.PHONY: all env install clean build-android build-android-release build-ios-dev build-ios build-ios-release test run

SHELL := /usr/bin/env bash

ifdef PROJECT_API_HOST
    RUN_ARGS := --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
else
    RUN_ARGS :=
endif

all: test

env:
	cp -n .env.example .env | true

install: env
	flutter pub get

clean:
	flutter clean

build-android: install
	flutter build apk --debug

build-android-release: install
	flutter build appbundle --release

build-ios-dev: install
	flutter build ios

build-ios: install
	flutter build ios --debug --no-codesign

build-ios-release: install
	flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

test: install
	flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
	flutter test --no-pub --coverage

run: install
	flutter run $(RUN_ARGS)
