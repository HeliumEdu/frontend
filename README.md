<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/frontend/build.yml)](https://github.com/HeliumEdu/frontend/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/heliumedu/frontend)

# Helium Frontend

The `frontend` for [Helium](https://www.heliumedu.com/), including mobile and web deployments.

## Prerequisites

- Dart & Flutter
- Android or iOS Emulator
- ChromeDriver (for Integration Tests)

## Getting Started

## Development

To build a development versions of the app for Android and iOS, execute:

```sh
make build-android
make build-ios
```

Tun run a development version of the app for `web`, executing:

```sh
make run-devserver
```

Before commits are made, be sure to also run tests.

```sh
make test
make test-integration
```

When running a local `web` version of the project but hitting `prod` APIs, CORS will need to be disabled
by passing a flag like `--web-browser-flag=--disable-web-security` to Flutter so it starts the browser with this
disabled.

### Platform

The backend `platform` is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
If `platform` has been provisioned and is running locally, and you would like to run the frontend against the local
backend instead of production, run with `--dart-define PROJECT_API_HOST=http://localhost:8000`, or use `PROJECT_API_HOST=http://localhost:8000 make run-devserver`.

Note that to reach `localhost` from within an Android emulator, use `10.0.2.2` instead.

## Local Docker (Web)

The web app can be built and served locally in Docker as a static SPA on port `8080`.

```sh
make
```

The Docker image serves the built Flutter web assets on `http://localhost:8080`.
