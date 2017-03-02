ENTRYPOINT ?= web
SERVERNAME ?= demo
VM_NAME ?= cdn

all:
	@echo "usage:\tmake create-vm VM_NAME=$(VM_NAME) \t-- create a VM machine"
	@echo "\tmake cdn \t\t\t-- configure the cdn"
	@echo "\tmake clean \t\t\t-- undeploy the cdn and remove the VM"
	@echo "\tmake debug \t\t\t-- launches a debug shell into the latest intermediate docker image"
	@echo "\tmake run-consul \t\t-- install consul (only)"
	@echo "\tmake run-registrator \t\t-- install registrator (only)"
	@echo "\tmake run-haproxy \t\t-- install haproxy (only)"
	@echo "\tmake run-template \t\t-- show current consul template"
	@echo "\tmake demo \t\t\t-- execute the installation of demos"

create-vm:
	-docker-machine create --driver=virtualbox $(VM_NAME)
	-@echo "\n#> Run this command to configure your shell:" 
	-@echo '#> eval $$(docker-machine env $(VM_NAME))'
	-@echo "#> Afterwards execute: make cdn"
	-@echo ""

cdn-url:
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-@docker-machine ls
	-@echo "\nConsul Admin URL: http://$(DOCKER_IP):8500/"
	-@echo "HAproxy Stats URL: http://$(DOCKER_IP):1936/ (user:admin, pass:password)\n"

cdn: run-consul run-registrator run-haproxy cdn-url

ifeq ($(JOIN_NODE),)
run-consul:
	-@echo "- setting up a cluster server"
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-docker run --name consul -d -h $(DOCKER_MACHINE_NAME) \
	-p $(DOCKER_IP):8300:8300 \
	-p $(DOCKER_IP):8301:8301 \
	-p $(DOCKER_IP):8301:8301/udp \
	-p $(DOCKER_IP):8302:8302 \
	-p $(DOCKER_IP):8302:8302/udp \
	-p $(DOCKER_IP):8400:8400 \
	-p $(DOCKER_IP):8500:8500 \
	consul:latest agent -server -ui \
	-client=0.0.0.0 \
	-advertise=$(DOCKER_IP) \
	-bootstrap-expect=1 
	-@docker exec -t consul consul members
	-@echo "- consul web ui: http://$(DOCKER_IP):8500/"
else  
run-consul:
	-@echo "- setting up a client node"
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-docker run --name consul -d -h $(DOCKER_MACHINE_NAME) \
	-p $(DOCKER_IP):8300:8300 \
	-p $(DOCKER_IP):8301:8301 \
	-p $(DOCKER_IP):8301:8301/udp \
	-p $(DOCKER_IP):8302:8302 \
	-p $(DOCKER_IP):8302:8302/udp \
	-p $(DOCKER_IP):8400:8400 \
	-p $(DOCKER_IP):8500:8500 \
	consul:latest agent -ui \
	-client=0.0.0.0 \
	-advertise=$(DOCKER_IP) \
	-join $(JOIN_NODE) 
	-@docker exec -t consul consul members
	-@echo "- consul web ui: http://$(DOCKER_IP):8500/"
endif

run-registrator:
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-docker run -d -v /var/run/docker.sock:/tmp/docker.sock \
	-h registrator --name registrator gliderlabs/registrator \
	consul://$(DOCKER_IP):8500

run-template:
	-docker run --dns 172.17.42.1 --rm brunosimoes/haproxy -consul=$(shell docker-machine ip $(DOCKER_MACHINE_NAME)):8500 -dry -once

run-haproxy:
	-docker build -t brunosimoes/haproxy haproxy/
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-docker run -d -e HAPROXY_STATS=true \
		-e HAPROXY_DOMAIN=$(DOCKER_IP) \
		-e SERVICE_NAME=rest --name=haproxy \
		--dns 172.17.42.1 \
		-p $(DOCKER_IP):80:80 \
		-p $(DOCKER_IP):1936:1936 \
		brunosimoes/haproxy -consul=$(DOCKER_IP):8500

clean:
	-docker rm $(docker ps --all -q -f status=dead)
	-docker-machine rm $(VM_NAME) # remove the vm machine
	-docker system prune # remove all unused data.
	-docker system df # show used space

debug:
	docker run -t -i `docker images -q | head -n 1` /bin/bash

demo:
	-docker build -t brunosimoes/tinyweb tinyweb/ || exit 
	-docker run -d -e SERVICE_NAME=demo/hello -e SERVICE_TAGS=rest -h serv1 --name serv1 -p :80 brunosimoes/tinyweb 
	-docker run -d -e SERVICE_NAME=demo/hello -e SERVICE_TAGS=rest -h serv2 --name serv2 -p :80 brunosimoes/tinyweb 
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME))) 
	-echo "\nEntry-point URL: http://$(DOCKER_IP):80/demo/hello\n"

webserver:
	-docker build -t brunosimoes/nginx nginx/
	-docker run -d -e SERVICE_NAME=$(ENTRYPOINT) -e SERVICE_TAGS=rest -h $(SERVERNAME) --name $(SERVERNAME) -p :80 brunosimoes/nginx
	-$(eval DOCKER_IP := $(shell docker-machine ip $(DOCKER_MACHINE_NAME)))
	-@echo "\nEntry-point URL: http://$(DOCKER_IP):80/$(ENTRYPOINT)\n"
