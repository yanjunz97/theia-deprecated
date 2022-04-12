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

.PHONY: verify
verify:
	@echo "===> Verifying spellings <==="
	GO=$(GO) $(CURDIR)/hack/verify-spelling.sh
	@echo "===> Verifying Table of Contents <==="
	GO=$(GO) $(CURDIR)/hack/verify-toc.sh
	@echo "===> Verifying documentation formatting for website <==="
	$(CURDIR)/hack/verify-docs-for-website.sh

.PHONY: toc
toc:
	@echo "===> Generating Table of Contents for Antrea docs <==="
	GO=$(GO) $(CURDIR)/hack/update-toc.sh

.PHONE: markdownlint
markdownlint:
	@echo "===> Running markdownlint <==="
	markdownlint -c .markdownlint-config.yml -i CHANGELOG/ -i CHANGELOG.md .

.PHONE: markdownlint-fix
markdownlint-fix:
	@echo "===> Running markdownlint <==="
	markdownlint --fix -c .markdownlint-config.yml -i CHANGELOG/ -i CHANGELOG.md .

.PHONY: spelling-fix
spelling-fix:
	@echo "===> Updating incorrect spellings <==="
	$(CURDIR)/hack/update-spelling.sh
