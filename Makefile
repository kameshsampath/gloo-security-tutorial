SHELL := /usr/bin/env bash
ENV_FILE := .env
include ${ENV_FILE}
export $(shell sed 's/=.*//' ${ENV_FILE})
CURRENT_DIR = $(shell pwd)

.PHONY: create	stop	delete	clean	build	push

.create:
	./bin/start-minikube.sh

.stop:
	@minikube -p$(PROFILE_NAME) stop 

.delete:	stop
	@minikube -p$(PROFILE_NAME) delete 

clean:	
	@eval $$(minikube -p $(PROFILE_NAME) docker-env); \
	docker rmi $(IMAGE_TAG)

build:
	@eval $$(minikube -p $(PROFILE_NAME) docker-env); \
	docker build --rm -t $(IMAGE_TAG) -f Dockerfile $(CURRENT_DIR)

push:	build
	@eval $$(minikube -p $(PROFILE_NAME) docker-env); \
	docker push $(IMAGE_TAG)
