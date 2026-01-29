<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

[![Coverage](https://img.shields.io/codecov/c/github/HeliumEdu/frontend)](https://codecov.io/gh/HeliumEdu/frontend)
[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/frontend/build.yml)](https://github.com/HeliumEdu/frontend/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/heliumedu/frontend)

# Helium Frontend

**NOTE: This is the new Helium frontend. It is still under active development.**

The `frontend` for [Helium](https://www.heliumedu.com/), including mobile and web deployments.

## Prerequisites

- Dart (>= 3.10)
- Flutter (>= 3.38)
- Android or iOS Emulator

## Getting Started

## Development

With an emulator running, you can start the app by executing:

```sh
make run
```

To build a development version of the app Android or iOS, execute:

```sh
make build-android
make build-ios
```

Before commits are made, be sure to also run tests.

```sh
make test
```

When running a local `web` version of the project but hitting `prod` APIs, CORS will need to be disabled
by passing a flag like `--web-browser-flag=--disable-web-security` to Flutter so it starts the browser with this
disabled.

### Platform

The backend `platform` is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
If `platform` has been provisioned and is running locally, and you would like to run the frontend against the local
backend instead of production, set the environment variable `PROJECT_API_HOST` before executing `make run`.

Note that to reach `localhost` from within an Android emulator, use `10.0.2.2` instead of `127.0.0.1`.
