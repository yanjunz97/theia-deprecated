SHELL              := /bin/bash
# go options
GO                 ?= go
LDFLAGS            :=
GOFLAGS            :=
BINDIR             ?= $(CURDIR)/bin
GO_FILES           := $(shell find . -type d -name '.cache' -prune -o -type f -name '*.go' -print)
GOPATH             ?= $$($(GO) env GOPATH)
DOCKER_CACHE       := $(CURDIR)/.cache
GO_VERSION         := $(shell head -n 1 build/images/deps/go-version)

DOCKER_BUILD_ARGS = --build-arg GO_VERSION=$(GO_VERSION)

include versioning.mk

.PHONY: clickhouse-monitor
clickhouse-monitor:
	@echo "===> Building aurorazhou/theia-clickhouse-monitor Docker image <==="
	docker build --pull -t aurorazhou/theia-clickhouse-monitor:$(DOCKER_IMG_VERSION) -f build/images/Dockerfile.clickhouse-monitor.ubuntu $(DOCKER_BUILD_ARGS) .
	docker tag aurorazhou/theia-clickhouse-monitor:$(DOCKER_IMG_VERSION) aurorazhou/theia-clickhouse-monitor
