.PHONY: all install build migrate test

all: install build migrate test

install:
	npm install

build:
	npm run build

migrate:
	echo "Nothing to migrate."

test:
	npm run test
