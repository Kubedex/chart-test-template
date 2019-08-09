SHELL := /bin/bash
REPO := $(notdir $(CURDIR))
NAME := $(REPO)
CHARTNAME := $(shell ls -1d */ | sed 's\#/\#\#' | grep -v 'tools')
K3SVER := v0.7.0

REGISTRYID := 000000000000
REGISTRYREGION := us-east-1
ECRTOKEN := $(shell aws ecr get-login --region $(REGISTRYREGION) --registry-ids $(REGISTRYID) | cut -d' ' -f6)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: run chart lint test

clean:  ## Kills container and leaves image for this module
	@echo "Killing Container"
	@bash -c "docker kill $(NAME) > /dev/null 2>&1 || true"
	@bash -c "docker rm -f $(NAME) > /dev/null 2>&1 || true"

run:  ## Creates a docker network, runs this module image with volumes and default opts
	@echo "Running Container"
	@bash -c "docker run --privileged -d \
	--name $(NAME) \
	--tmpfs /run \
	--tmpfs /var/run \
	rancher/k3s:$(K3SVER) server --no-deploy traefik"
	@bash -c "docker exec -t $(NAME) sh -c 'iptables -t nat -I POSTROUTING -s 10.42.0.0/16 -d 10.42.0.0/16 -j MASQUERADE'"
	@bash -c "docker cp tools/helm $(NAME):/bin/helm"
	@bash -c "docker cp tools/tiller $(NAME):/bin/tiller"
	@bash -c "docker cp tools/imagepullsecret.sh $(NAME):/bin/imagepullsecret"
	@bash -c "docker exec -t $(NAME) sh -c 'sleep 10'"
	@bash -c "docker exec -t $(NAME) sh -c 'mkdir -p /.kube && kubectl config view --raw > /.kube/config'"
	@bash -c "docker exec -t $(NAME) sh -c 'imagepullsecret $(CHARTNAME) $(REGISTRYID) $(REGISTRYREGION) $(ECRTOKEN)'"
	@bash -c "docker exec -t $(NAME) sh -c 'kubectl create clusterrolebinding system:default --clusterrole=cluster-admin --serviceaccount=kube-system:default'"
	@bash -c "docker exec -t $(NAME) sh -c 'helm init --wait'"

chart:  ## Installs the chart
	@echo "Installing Helm Chart"
	@bash -c "docker cp $(CHARTNAME) $(NAME):/"
	@bash -c "docker cp values.yaml $(NAME):/"
	@bash -c "docker exec -t $(NAME) sh -c 'helm upgrade --install --wait --atomic --cleanup-on-fail --force $(CHARTNAME) /$(CHARTNAME) --namespace $(CHARTNAME) -f values.yaml'"

chartrm:  ## Uninstalls the chart
	@echo "Uninstalling Helm Chart"
	@bash -c "docker cp $(CHARTNAME) $(NAME):/"
	@bash -c "docker cp values.yaml $(NAME):/"
	@bash -c "docker exec -t $(NAME) sh -c 'helm del --purge $(CHARTNAME)'"

lint:  ## Lints the chart
	@echo "Linting Helm Chart"
	@bash -c "docker cp $(CHARTNAME) $(NAME):/"
	@bash -c "docker cp values.yaml $(NAME):/"
	@bash -c "docker exec -t $(NAME) sh -c 'helm lint /$(CHARTNAME)'"

test:  ## Execs into the container, and runs inspec tests
	@echo "Running Tests"
	@bash -c "docker cp $(CHARTNAME) $(NAME):/"
	@bash -c "docker cp values.yaml $(NAME):/"
	@bash -c "docker exec -t $(NAME) sh -c 'helm test --cleanup $(CHARTNAME)'"

status:  ## Lists the docker container for this module
	@bash -c "docker ps --filter name=$(NAME)"

ssh:  ## Execs into bash on the container for this module
	@bash -c "docker exec -ti $(NAME) /bin/sh"

.DEFAULT_GOAL := all
.PHONY: all clean run chart chartrm lint test status ssh
