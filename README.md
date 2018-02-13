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
TBD

### Local Development
This is the simplest way to get started with minimal effort. Before starting the frontend development server, ensure the
[`platform`](https://github.com/HeliumEdu/platform) server is running at http://localhost:8000. Then, to get going
(assuming you have followed the "Getting Started" directions above), simply start the frontend server with:

```
npm run start
```

A development server will be started at http://localhost:3000.
