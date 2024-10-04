<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

[![Build](https://img.shields.io/github/actions/workflow/status/HeliumEdu/frontend/build.yml)](https://github.com/HeliumEdu/frontend/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/heliumedu/frontend)

# Helium Frontend Project

## Prerequisites

- Docker
- Node (>= 18)

## Getting Started

Note that this project is largely a placeholder. It was used to split out `frontend` code from the backend `platform`
while the `frontend` code would be rewritten in React. However, as the project is no longer actively maintained, there
is no current plant for this redevelopment. So, be aware that [Webpack](https://webpack.js.org/) is being used in a very hacky way (for
instance, the generated bundle is useless and should be ignored), [Nunjucks](https://mozilla.github.io/nunjucks/), is being used to process HTML
templates, and ultimately, this is legacy code that, if the project ever goes back in to active development, would
be completely overhauled.

## Development
### Docker Setup

To provision the Docker container with the `frontend` build, execute:

```sh
bin/runserver
```

This builds and starts a container named `helium_frontend`. Once running, the `frontend` is available at
http://localhost:3000. The shell of containers can be accessed with:

```shell
docker exec -it helium_frontend /bin/bash
```

Note that, since part of the way this build was hacked together circumvents many of Webpack's most useful features,
live changes will not be detected at this time and would require a restart of this server.

Before commits are made, be sure to run tests and check the generated coverage report

```sh
make test
```

### Platform

The backend `platform` is served from a separate repository and can be found [here](https://github.com/HeliumEdu/platform#readme).
Using Docker, the `frontend` and `platform` containers can be started alongside each other using to fully emulate
a production environment using [the deploy project](https://github.com/HeliumEdu/deploy).
