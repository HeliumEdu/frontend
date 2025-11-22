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

This project is the result of separating the `frontend` code from the backend `platform`, with the intention of someday
rewriting it in a modern framework. But we have not had the capacity (or expertise) to do that. Are you a frontend
expert in search of an open source project and interested in joining forces? [Reach out](mailto:contact@alexlaird.com)
and let us know!

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
Assuming `platform` has been provisioned and is running locally, setting `PROJECT_API_HOST` to point to the local host
instead of production can be accomplished by passing this when running Dart to start an Android emulator:

```sh
--dart-define=PROJECT_API_HOST=http://10.0.2.2:8000
```
