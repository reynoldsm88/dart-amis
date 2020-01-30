PACKER_EXEC := $(PACKER_HOME)/bin/packer
ROOT_DIR := $(shell pwd)

centos:
	@echo "using packer exec $(PACKER_EXEC)"
	cd centos7 && $(PACKER_EXEC) build centos7-ami.json