FROM ghcr.io/cirruslabs/flutter:3.38.9 AS build

ARG PROJECT_API_HOST=
ARG SENTRY_RELEASE=

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN set -eux; \
    BUILD_ARGS=""; \
    if [ -n "${PROJECT_API_HOST:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=PROJECT_API_HOST=${PROJECT_API_HOST}"; fi; \
    if [ -n "${SENTRY_RELEASE:-}" ]; then BUILD_ARGS="$BUILD_ARGS --dart-define=SENTRY_RELEASE=${SENTRY_RELEASE}"; fi; \
    flutter build web --release --source-maps $BUILD_ARGS; \
    dart tool/update_version.dart

######################################################################

FROM ubuntu:24.04 AS frontend_web

RUN apt-get --fix-missing update \
    && apt-get install -y --no-install-recommends apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

COPY container/apache-000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY container/apache-ports.conf /etc/apache2/ports.conf
COPY container/apache-mod-servername.conf /etc/apache2/mods-enabled/servername.conf

ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_RUN_USER=ubuntu

WORKDIR /app

COPY --from=build --chown=ubuntu:ubuntu /app/build/web .

EXPOSE 8080

CMD ["apache2ctl", "-D", "FOREGROUND"]
