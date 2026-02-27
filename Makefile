IMAGE_NAME ?= cppformat
IMAGE_FILE ?= $(IMAGE_NAME).tar.gz

.PHONY: build docker-build docker-save docker-run

build:
	dub build

docker-build:
	docker build -t $(IMAGE_NAME) .

docker-save: docker-build
	docker save $(IMAGE_NAME) | gzip > $(IMAGE_FILE)

docker-run: docker-build
	docker run --rm -p 8080:8080 $(IMAGE_NAME)

-include Makefile.local
