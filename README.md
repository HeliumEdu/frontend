[![Build Status](https://travis-ci.org/HeliumEdu/frontend.svg?branch=master)](https://travis-ci.org/HeliumEdu/frontend)
[![codecov](https://codecov.io/gh/HeliumEdu/frontend/branch/master/graph/badge.svg)](https://codecov.io/gh/HeliumEdu/frontend)


# Helium Frontend Project

## Prerequisites
* NPM (>= 5.6)

## Getting Started
The Frontend is developed using [React](https://reactjs.org/).

### Project Setup
To setup the React Frontend build environment, execute:

```
make install
```

Before commits are made, be sure to run tests and check the generated coverage report

```
make test
```

## Development
### Vagrant Development
To emulate a prod-like environment, use the Vagrant box. It's setup is described more thoroughly in the [deploy](https://github.com/HeliumEdu/deploy)
project. This is the recommended way to develop and test for production as this environment is provisioned in the same way other prod-like
environments are deployed and interacts with related projects as necessary.

As the Vagrant environment does take a bit more time to setup (even though the setup is largely automated) and can consume more developer
and system resources, the local development environment described below is the quickest and easiest way to get up and running.

### Local Development
This is the simplest way to get started with minimal effort. Before starting the frontend development server, ensure the
[`platform`](https://github.com/HeliumEdu/platform) server is running at http://localhost:8000. Then, to get going
(assuming you have followed the "Getting Started" directions above), you should have the REACT_APP_ENV environment
variable set to "dev", then simply start the frontend server with:

```
npm run start
```

A development server will be started at http://localhost:3000.

Note that environment-specific credentials are stored in corresponding .env.{{ domain_environment }} files committed to
this repository. As these are frontned environment variables, there are no sensitive details here, so any environment's
configuration can safely be committed to the repository.
