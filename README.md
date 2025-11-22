<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/mobile/build.yml)](https://github.com/HeliumEdu/mobile/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/heliumedu/mobile)

# Helium Mobile

The `mobile` app for [Helium Edu](https://www.heliumedu.com/). This project is still in development, and we hope to
release it for Android and iOS near the beginning of 2026.

## Prerequisites

- Dart (>= 3.10)
- Flutter (>= 3.38)
- Android (or iOS) Emulator

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

### Platform

The backend `platform` is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
If `platform` has been provisioned and is running locally, and you would like to run the mobile app against the local
backend instead of production, set the environment variable `PROJECT_API_HOST` before executing `make run`.

Note that to reach `localhost` from within an Android emulator, use `10.0.2.2` instead of `127.0.0.1`.
