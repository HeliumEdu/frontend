.PHONY: all env install clean clean-chrome icons build-android build-android-release build-ios-dev build-ios build-ios-release update-version firebase-config build-web upload-web-sourcemaps test test-integration test-integration-smoke coverage run-devserver build-docker run-docker stop-docker restart-docker publish

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64
DOCKER_TAG_VERSION := $(subst +,_,$(TAG_VERSION))
DOCKER_CACHE_DIR ?= .docker-cache

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

# Integration test configuration
ENVIRONMENT ?= dev-local
INTEGRATION_TARGET ?= integration_test/app_test.dart
INTEGRATION_HEADLESS ?= true
# Set API host based on environment
ifeq ($(ENVIRONMENT),dev-local)
    PROJECT_API_HOST ?= http://localhost:8000
endif
DRIVE_ARGS := --driver=test_driver/integration_test.dart -d web-server --browser-name=chrome --profile --dart-define=ENVIRONMENT=$(ENVIRONMENT) --dart-define=ANALYTICS_ENABLED=false --test-arguments=test --test-arguments=--reporter=expanded
ifeq ($(INTEGRATION_HEADLESS),true)
    DRIVE_ARGS += --headless
else
    DRIVE_ARGS += --no-headless
endif
ifdef PROJECT_API_HOST
    DRIVE_ARGS += --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
endif
ifdef AWS_S3_ACCESS_KEY_ID
    DRIVE_ARGS += --dart-define=AWS_S3_ACCESS_KEY_ID=$(AWS_S3_ACCESS_KEY_ID)
endif
ifdef AWS_S3_SECRET_ACCESS_KEY
    DRIVE_ARGS += --dart-define=AWS_S3_SECRET_ACCESS_KEY=$(AWS_S3_SECRET_ACCESS_KEY)
endif

all: test

env:
	cp -n .env.example .env | true

install: env
	flutter pub get

clean:
	flutter clean

clean-chrome:
	@echo "Killing stale Chrome and chromedriver processes..."
	@pkill -f chromedriver || true
	@pkill -f "Chrome.*--remote-debugging" || true
	@pkill -f "Google Chrome for Testing" || true
	@sleep 1
	@echo "Done"

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

icons:
	flutter pub run flutter_launcher_icons
	cp web/icons/Icon-192.png web/favicon.png

update-version:
	dart bin/update_version.dart

firebase-config:
	flutterfire config --project=helium-edu --yes

build-web: install
	flutter build web --release --source-maps --no-tree-shake-icons $(WEB_ARGS)
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

test-integration: clean-chrome
ifeq ($(ENVIRONMENT),dev-local)
	@curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/platform/main/bin/start-platform.sh?$$(date +%s)" | bash
	@chromedriver --port=4444 & sleep 2 && flutter drive --target=$(INTEGRATION_TARGET) $(DRIVE_ARGS); TEST_EXIT=$$?; \
		pkill -f chromedriver || true; \
		(curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/platform/main/bin/stop-platform.sh?$$(date +%s)" | bash > /dev/null 2>&1 &); \
		exit $$TEST_EXIT
else
	@chromedriver --port=4444 & sleep 2 && flutter drive --target=$(INTEGRATION_TARGET) $(DRIVE_ARGS); TEST_EXIT=$$?; pkill -f chromedriver || true; exit $$TEST_EXIT
endif

test-integration-smoke: clean-chrome
	@chromedriver --port=4444 & sleep 2 && flutter drive --target=integration_test/smoke_test.dart $(DRIVE_ARGS); TEST_EXIT=$$?; pkill -f chromedriver || true; exit $$TEST_EXIT

coverage:
	dart pub global activate test_cov_console
	lcov -o coverage/lcov.info --remove coverage/lcov.info 'lib/config/*' 'lib/utils/app_globals.dart' 'lib/utils/app_style.dart' 'lib/utils/color_helpers.dart' 'lib/data/models/*' 'lib/data/repositories/*' 'lib/presentation/core/*' 'lib/presentation/navigation/*' 'lib/presentation/ui/*' 'lib/presentation/features/auth/views/*' 'lib/presentation/features/courses/dialogs/*' 'lib/presentation/features/courses/views/*' 'lib/presentation/features/courses/widgets/*' 'lib/presentation/features/grades/dialogs/*' 'lib/presentation/features/grades/views/*' 'lib/presentation/features/planner/dialogs/*' 'lib/presentation/features/planner/views/*' 'lib/presentation/features/planner/widgets/*' 'lib/presentation/features/resources/dialogs/*' 'lib/presentation/features/resources/views/*' 'lib/presentation/features/resources/widgets/*' 'lib/presentation/features/settings/dialogs/*' 'lib/presentation/features/settings/views/*' 'lib/presentation/features/shared/widgets/*'
	dart pub global run test_cov_console

run-devserver: install
ifeq ($(USE_NGROK),true)
	$(eval RUN_ARGS += --release)
	@( \
		python3 -m pip install pyngrok; \
		ngrok start heliumedu --log stdout & \
	)
endif
	flutter run $(RUN_ARGS)

build-docker:
	mkdir -p $(DOCKER_CACHE_DIR)
	docker buildx build \
		--build-arg PROJECT_API_HOST=$(PROJECT_API_HOST) \
		--build-arg SENTRY_RELEASE=$(SENTRY_RELEASE) \
		--cache-from=type=local,src=$(DOCKER_CACHE_DIR) \
		--cache-to=type=local,dest=$(DOCKER_CACHE_DIR),mode=max \
		-t helium/frontend-web:$(PLATFORM)-latest \
		-t helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION) \
		--platform=linux/$(PLATFORM) \
		--load .

run-docker:
	docker compose up -d

stop-docker:
	docker compose stop

restart-docker: stop-docker run-docker

publish: build-docker
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/heliumedu

	docker tag helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION) public.ecr.aws/heliumedu/helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION)
	docker push public.ecr.aws/heliumedu/helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION)

	docker create --name frontend-web helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION)
	docker cp frontend-web:/app build
	aws s3 sync build "s3://heliumedu/helium/frontend-web/$(TAG_VERSION)"
