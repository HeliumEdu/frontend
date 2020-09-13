[![Build Status](https://travis-ci.org/HeliumEdu/frontend.svg?branch=master)](https://travis-ci.org/HeliumEdu/frontend)
![GitHub](https://img.shields.io/github/license/heliumedu/frontend)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.me/alexdlaird)

# Helium Frontend Project

<p align="center"><img src="https://www.heliumedu.com/assets/img/logo_full_blue.png" /></p>

## Prerequisites

- NPM (>= 5.6)

## Getting Started
Note that this project is largely a placeholder. It has been used to split out frontend code from the backend, and it
loosely maintained while the React rewrite of this project is completed. However, in the meantime, please be aware that
[Webpack](https://webpack.js.org/) is being used in a very hacky way (for instance, the generated bundle is useless and
should be ignored), [Nunjucks](https://mozilla.github.io/nunjucks/), is being used to process HTML templates, and
ultimately, this is legacy code that is being completely overhauled.

### Project Setup
To setup the Frontend build environment, execute:

```sh
make install
```

Before commits are made, be sure to run tests and check the generated coverage report

```sh
make test
```

## Development
### Vagrant Development
To emulate a prod-like environment, use the Vagrant box. It's setup is described more thoroughly in the [deploy](https://github.com/HeliumEdu/deploy#readme)
project. This is the recommended way to develop and test for production as this environment is provisioned in the same way other prod-like
environments are deployed and interacts with related projects as necessary.

As the Vagrant environment does take a bit more time to setup (even though the setup is largely automated) and can consume more developer
and system resources, the local development environment described below is the quickest and easiest way to get up and running.

Note that Vagrant relies on a built version of the frontend code to best simulate a prod-like environment. Thus, each
time code changes are made, `make build` will need to be run for them to take effect.

### Local Development
This is the simplest way to get started with minimal effort. Before starting the frontend development server, ensure the
[platform](https://github.com/HeliumEdu/platform#readme) server is running at http://localhost:8000. Then, to get going
(assuming you have followed the "Getting Started" directions above), then simply start the frontend server with:

```sh
bin/runserver
```

A development server will be started at http://localhost:3000. Note however that, since part of the way this build was
hacked together circumvents many of Webpack's most useful features, live changes will not be detected at this time and
would require a restart of this server.
