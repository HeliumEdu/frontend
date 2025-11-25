<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/frontend/build.yml)](https://github.com/HeliumEdu/frontend/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/heliumedu/frontend)

# Helium Frontend

The `frontend` for [Helium](https://www.heliumedu.com/).

Released container images are published to [Helium's AWS ECR](https://gallery.ecr.aws/heliumedu/).

## Prerequisites

- Docker
- Node (>= 20)

## Getting Started

This project is the result of separating the `frontend` code from the backend `platform`, with the intention of someday
rewriting it in a modern framework. But we have not had the capacity (or expertise) to do that. Are you a frontend
expert in search of an open source project and interested in joining forces? [Reach out](mailto:contact@alexlaird.com)
and let us know!

Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it. In its current
form, [Nunjucks](https://mozilla.github.io/nunjucks/) is being used to process HTML templates, and way JavaScript and Ajax are being used is pretty
dated.

## Development

### Docker Setup

To provision the Docker container with the `frontend` build, execute:

```sh
make
```

This builds and starts a container named `frontend-frontend-1`. Once running, the `frontend` is available at
http://localhost:3000. The shell of the container can be accessed with:

```sh
docker exec -it frontend-frontend-1 /bin/bash
```

Before commits are made, be sure to run tests and check the generated coverage report.

```sh
make test
```

#### Image Architecture

By default, the Docker image will be built for `linux/arm64`. To build a native image on an `x86` architecture
instead, set `PLATFORM=amd64`.

### Platform

The backend `platform` is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
Using Docker, the `frontend` and `platform` containers can be started alongside each other to almost entirely
emulate a `prod`-like environment locally using [the `deploy` project](https://github.com/HeliumEdu/deploy). For
functionality that still requires Internet-connected external services (ex. emails and text messages), provision
[the `dev-local` Terraform Workspace](https://github.com/HeliumEdu/deploy/tree/main/terraform/environments/dev-local),
which is meant to work alongside local Docker development. 