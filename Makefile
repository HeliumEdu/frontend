.PHONY: all env install clean build-android build-android-release build-ios-dev build-ios build-ios-release update-version build-web upload-web-sourcemaps test coverage run

SHELL := /usr/bin/env bash

RUN_ARGS :=

ifneq ($(HEADLESS),false)
    RUN_ARGS += -d web-server
else
	RUN_ARGS += --web-browser-flag=--disable-web-security
endif

ifdef PROJECT_API_HOST
    RUN_ARGS += --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
endif

ifdef PORT
    RUN_ARGS += --web-port=$(PORT)
else
    RUN_ARGS += --web-port=8080
endif

ifdef SENTRY_RELEASE
    WEB_ARGS := --dart-define=SENTRY_RELEASE=$(SENTRY_RELEASE)
else
    WEB_ARGS :=
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
	flutter build appbundle --release --obfuscate --split-debug-info=build/symbols

build-ios-dev: install
	flutter build ios

build-ios: install
	flutter build ios --debug --no-codesign

build-ios-release: install
	flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --obfuscate --split-debug-info=build/symbols

update-version:
	dart tool/update_version.dart

build-web: install
	flutter build web --release --source-maps $(WEB_ARGS)
	$(MAKE) update-version

upload-web-sourcemaps:
ifndef SENTRY_RELEASE
	$(error SENTRY_RELEASE is required)
endif
	SENTRY_PROPERTIES=sentry.properties sentry-cli releases new $(SENTRY_RELEASE)
	SENTRY_PROPERTIES=sentry.properties sentry-cli sourcemaps upload --release $(SENTRY_RELEASE) build/web
	SENTRY_PROPERTIES=sentry.properties sentry-cli releases finalize $(SENTRY_RELEASE)

test: install
	flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
	flutter test --no-pub --coverage

coverage:
	dart pub global activate test_cov_console
	lcov -o coverage/lcov.info --remove coverage/lcov.info 'lib/config/*' 'lib/utils/app_globals.dart' 'lib/utils/app_style.dart' 'lib/utils/color_helpers.dart' 'lib/data/models/*' 'lib/data/repositories/*' 'lib/presentation/dialogs/*' 'lib/presentation/controllers/*' 'lib/presentation/views/*' 'lib/presentation/widgets/*'
	dart pub global run test_cov_console

run: install
ifeq ($(USE_NGROK),true)
	$(eval RUN_ARGS += --release)
	@( \
		python3 -m pip install pyngrok; \
		ngrok start heliumedu --log stdout & \
	)
endif
	flutter run $(RUN_ARGS)
