FROM ubuntu:24.04 AS flutter-sdk

ARG FLUTTER_VERSION=stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        make \
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

ARG FIREBASE_AUTH_DOMAIN=
ARG PROJECT_API_HOST=
ARG RELEASE_VERSION=
ARG SENTRY_DIST=
ARG SENTRY_DSN=
ARG SENTRY_ENVIRONMENT=

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# The same build as CI's. PROJECT_API_HOST is always passed so an empty value
# leaves the app deriving its API host from where it's served.
RUN make build-web \
    FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN}" \
    PROJECT_API_HOST="${PROJECT_API_HOST}" \
    RELEASE_VERSION="${RELEASE_VERSION}" \
    SENTRY_DIST="${SENTRY_DIST}" \
    SENTRY_DSN="${SENTRY_DSN}" \
    SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT}"

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
