.PHONY: all env install clean clean-chrome icons build-android build-android-release build-ios-dev build-ios build-ios-release update-version firebase-config build-web test start-platform stop-platform test-integration test-integration-smoke test-playwright coverage run-devserver build-docker-local build-docker run-docker stop-docker restart-docker publish

SHELL := /usr/bin/env bash
TAG_VERSION ?= latest
PLATFORM ?= arm64
DOCKER_TAG_VERSION := $(subst +,_,$(TAG_VERSION))
DOCKER_CACHE_DIR ?= .docker-cache

ENVIRONMENT ?= dev-local
INTEGRATION_TARGET ?= integration_test/full_test.dart
INTEGRATION_HEADLESS ?= true
INTEGRATION_EMAIL_SUFFIX ?= integration-$(USER)
ifeq ($(ENVIRONMENT),prod)
    ENVIRONMENT_PREFIX :=
else
    ENVIRONMENT_PREFIX := $(ENVIRONMENT).
endif
ifeq ($(ENVIRONMENT),dev-local)
    PROJECT_API_HOST ?= http://localhost:8000
else
    PROJECT_API_HOST ?= https://api.$(ENVIRONMENT_PREFIX)heliumedu.com
endif

RELEASE_ARGS :=
ifdef RELEASE_VERSION
    RELEASE_ARGS += --dart-define=RELEASE_VERSION=$(RELEASE_VERSION)
endif
ifdef SENTRY_DIST
    RELEASE_ARGS += --dart-define=SENTRY_DIST=$(SENTRY_DIST)
endif
ifndef RELEASE_VERSION
    RELEASE_ARGS += --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
endif

RUN_ARGS :=
ifneq ($(HEADLESS),false)
    RUN_ARGS += -d web-server
else
	RUN_ARGS += --web-browser-flag=--disable-web-security
endif
RUN_ARGS += --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
ifdef LOG_LEVEL
    RUN_ARGS += --dart-define=LOG_LEVEL=$(LOG_LEVEL)
endif
ifdef PORT
    RUN_ARGS += --web-port=$(PORT)
else
    RUN_ARGS += --web-port=8080
endif

DRIVE_ARGS := --driver=test_driver/integration_test.dart -d web-server --web-port=8080 --browser-name=chrome --profile --dart-define=ENVIRONMENT=$(ENVIRONMENT) --dart-define=ANALYTICS_ENABLED=false
DRIVE_ARGS += --web-browser-flag="--disable-web-security"
DRIVE_ARGS += --web-browser-flag="--user-data-dir=/tmp/chrome_test_profile"
ifeq ($(INTEGRATION_HEADLESS),true)
    DRIVE_ARGS += --headless
else
    DRIVE_ARGS += --no-headless
endif
DRIVE_ARGS += --dart-define=PROJECT_API_HOST=$(PROJECT_API_HOST)
ifdef LOG_LEVEL
    DRIVE_ARGS += --dart-define=LOG_LEVEL=$(LOG_LEVEL)
endif
ifdef AWS_INTEGRATION_S3_ACCESS_KEY_ID
    DRIVE_ARGS += --dart-define=AWS_INTEGRATION_S3_ACCESS_KEY_ID=$(AWS_INTEGRATION_S3_ACCESS_KEY_ID)
endif
ifdef AWS_INTEGRATION_S3_SECRET_ACCESS_KEY
    DRIVE_ARGS += --dart-define=AWS_INTEGRATION_S3_SECRET_ACCESS_KEY=$(AWS_INTEGRATION_S3_SECRET_ACCESS_KEY)
endif
ifdef INTEGRATION_LOG_LEVEL
    DRIVE_ARGS += --dart-define=INTEGRATION_LOG_LEVEL=$(INTEGRATION_LOG_LEVEL)
endif
ifdef INTEGRATION_EMAIL_SUFFIX
    DRIVE_ARGS += --dart-define=INTEGRATION_EMAIL_SUFFIX=$(INTEGRATION_EMAIL_SUFFIX)
endif
ifdef RELEASE_VERSION
    DRIVE_ARGS += --dart-define=RELEASE_VERSION=$(RELEASE_VERSION)
endif
ifdef SENTRY_DIST
    DRIVE_ARGS += --dart-define=SENTRY_DIST=$(SENTRY_DIST)
endif

all: build-docker-local run-docker

env:
	cp -n .env.example .env | true

install: env
	flutter pub get

clean:
	flutter clean

clean-chrome:
	@echo "Killing stale Chrome and chromedriver processes ..."
	@pkill -f chromedriver || true
	@pkill -f "Chrome.*--remote-debugging" || true
	@pkill -f "Google Chrome for Testing" || true
	@sleep 1
	@echo "Done"

build-android: install
	flutter build apk --debug

build-android-release: install
	flutter build appbundle --release --obfuscate --split-debug-info=build/symbols $(RELEASE_ARGS)

build-ios-dev: install
	flutter build ios

build-ios: install
	flutter build ios --debug --no-codesign

build-ios-release: install
	flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --obfuscate --split-debug-info=build/symbols $(RELEASE_ARGS)

build-web: install
	flutter build web --release --source-maps --no-tree-shake-icons $(RELEASE_ARGS)
	cp -r web/.well-known build/web/
	rm -f build/web/.last_build_id
	$(MAKE) update-version

icons:
	flutter pub run flutter_launcher_icons
	cp web/icons/Icon-192.png web/favicon.png

update-version:
	dart bin/update_version.dart

firebase-config:
	flutterfire config --project=helium-edu --yes

test: install
	flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
	flutter test --no-pub --coverage

start-platform:
	@if curl -sf http://localhost:8000/status/ > /dev/null 2>&1; then \
		echo "Platform already running"; \
	else \
		echo "Starting platform ..."; \
		curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/platform/main/bin/start-platform.sh?$$(date +%s)" | bash; \
	fi
	@if [ -n "$$PLATFORM_EMAIL_HOST_USER" ] && [ -n "$$PLATFORM_EMAIL_HOST_PASSWORD" ]; then \
		WORK_DIR=$${TMPDIR:-/tmp}/helium-platform; \
		if grep -q '<SMTP_USERNAME>' "$$WORK_DIR/.env" 2>/dev/null; then \
			echo "Injecting SMTP credentials and restarting API ..."; \
			sed -i.bak "s/<SMTP_USERNAME>/$$PLATFORM_EMAIL_HOST_USER/" $$WORK_DIR/.env; \
			sed -i.bak "s/<SMTP_PASSWORD>/$$PLATFORM_EMAIL_HOST_PASSWORD/" $$WORK_DIR/.env; \
			cd $$WORK_DIR && docker compose up -d api worker; \
		fi; \
	fi

stop-platform:
	@curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/platform/main/bin/stop-platform.sh?$$(date +%s)" | bash

test-integration:
ifeq ($(ENVIRONMENT),dev-local)
	@$(MAKE) start-platform
endif
	@chromedriver --port=4444 & CHROME_PID=$$!; sleep 2 && flutter drive --target=$(INTEGRATION_TARGET) $(DRIVE_ARGS); TEST_EXIT=$$?; \
		kill $$CHROME_PID 2>/dev/null || true; \
		exit $$TEST_EXIT

test-integration-smoke:
	@chromedriver --port=4444 & CHROME_PID=$$!; sleep 2 && flutter drive --target=integration_test/smoke_test.dart $(DRIVE_ARGS); TEST_EXIT=$$?; kill $$CHROME_PID 2>/dev/null || true; exit $$TEST_EXIT

test-playwright:
	cd playwright && python3 -m pip install -r requirements.txt -q && python3 -m playwright install chromium && ENVIRONMENT=$(ENVIRONMENT) python3 -m pytest -v --screenshot=only-on-failure --output=screenshots

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

SENTRY_ENVIRONMENT ?= $(ENVIRONMENT)
FLUTTER_VERSION := $(shell tr -d '[:space:]' < .flutter-version)

build-docker-local: build-web
	docker build \
		--target frontend_web_local \
		-t helium/frontend-web:$(PLATFORM)-latest \
		-t helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION) \
		.

build-docker:
	mkdir -p $(DOCKER_CACHE_DIR)
	docker buildx build \
		--target frontend_web \
		--build-arg FLUTTER_VERSION=$(FLUTTER_VERSION) \
		--build-arg RELEASE_VERSION=$(RELEASE_VERSION) \
		--build-arg SENTRY_DIST=$(SENTRY_DIST) \
		--build-arg SENTRY_ENVIRONMENT=$(SENTRY_ENVIRONMENT) \
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

	docker tag helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION) public.ecr.aws/heliumedu/helium/frontend-web:$(PLATFORM)-latest
	docker push public.ecr.aws/heliumedu/helium/frontend-web:$(PLATFORM)-latest

	docker create --name frontend-web helium/frontend-web:$(PLATFORM)-$(DOCKER_TAG_VERSION)
	docker cp frontend-web:/app build
	aws s3 sync build "s3://heliumedu/helium/frontend-web/$(TAG_VERSION)"
