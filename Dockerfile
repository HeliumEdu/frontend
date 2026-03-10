FROM ubuntu:24.04 AS flutter-sdk

ARG FLUTTER_VERSION=stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter precache --web && \
    flutter config --no-analytics

######################################################################

FROM flutter-sdk AS build

ARG PROJECT_API_HOST=
ARG RELEASE_VERSION=
ARG SENTRY_DIST=
ARG SENTRY_ENVIRONMENT=

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN set -eux; \
    BUILD_ARGS=""; \
    if [ -n "${PROJECT_API_HOST:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=PROJECT_API_HOST=${PROJECT_API_HOST}"; fi; \
    if [ -n "${RELEASE_VERSION:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=RELEASE_VERSION=${RELEASE_VERSION}"; fi; \
    if [ -n "${SENTRY_DIST:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=SENTRY_DIST=${SENTRY_DIST}"; fi; \
    if [ -n "${SENTRY_ENVIRONMENT:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=SENTRY_ENVIRONMENT=${SENTRY_ENVIRONMENT}"; fi; \
    flutter build web --release --source-maps $BUILD_ARGS; \
    dart bin/update_version.dart

######################################################################

FROM ubuntu:24.04 AS frontend_web_base

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY container/nginx.conf /etc/nginx/nginx.conf

WORKDIR /app

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

######################################################################

# Full build: uses Flutter SDK stages above
FROM frontend_web_base AS frontend_web

COPY --from=build /app/build/web .

######################################################################

# Local build: uses pre-built artifacts from host (skips Flutter SDK stages)
FROM frontend_web_base AS frontend_web_local

COPY build/web .
