<p align="center">
  <img src="https://raw.githubusercontent.com/HeliumEdu/www/main/src/assets/img/helium-logo.png" alt="Helium" width="300" />
  <br />
  <img src="https://raw.githubusercontent.com/HeliumEdu/www/main/src/assets/img/og-default.png" alt="Helium - Student Planner" width="800" />
</p>

---

[**Helium**](https://www.heliumedu.com) is a free, color-coded online student planner for classes, homework, grades, and notes — the academic calendar built for the way you actually study.

<p align="center">
  <a href="https://apps.apple.com/us/app/helium-student-planner/id6758323154"><img src="https://raw.githubusercontent.com/HeliumEdu/www/main/src/assets/img/ios-badge.png" alt="Download on the App Store" height="50" /></a>
  &nbsp;
  <a href="https://play.google.com/store/apps/details?id=com.heliumedu.heliumapp"><img src="https://raw.githubusercontent.com/HeliumEdu/www/main/src/assets/img/play-badge.png" alt="Get it on Google Play" height="50" /></a>
</p>

<p align="center">
  <a href="https://www.patreon.com/alexdlaird/membership"><img src="https://raw.githubusercontent.com/HeliumEdu/www/main/public/img/support-patreon.svg" alt="Support on Patreon" height="30" /></a>
</p>

---

# Helium Frontend

[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/frontend/build.yml)](https://github.com/HeliumEdu/frontend/actions/workflows/build.yml)
[![Code Quality](https://app.codacy.com/project/badge/Grade/89c62152871f424e8d619be7a4d9ab50)](https://app.codacy.com/gh/HeliumEdu/frontend/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![GitHub License](https://img.shields.io/github/license/heliumedu/frontend)

The `frontend` for Helium - Student Planner, including mobile and web deployments.

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

### Platform API

The backend `platform` API is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
If `platform` has been provisioned and is running locally, and you would like to run the frontend against the local
backend instead of production, run with `--dart-define PROJECT_API_HOST=http://localhost:8000`, or use `PROJECT_API_HOST=http://localhost:8000 make run-devserver`.

Note that to reach `localhost` from within an Android emulator, use `10.0.2.2` instead.

## Local Docker (Web)

The web app can be built and served locally in Docker as a static SPA on port `--web-port=8080`.

```sh
make
```

The Docker image serves the built Flutter web assets on `http://localhost:8080`.
