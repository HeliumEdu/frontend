.PHONY: all install build test

all: install build migrate test

install:
	npm install

build:
	CI=true npm run build

test:
	CI=true npm run test
