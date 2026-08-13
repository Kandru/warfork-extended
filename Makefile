# warfork-extended — type `make` for help

-include config.mk

VERSION   := $(shell cat VERSION 2>/dev/null | tr -d '[:space:]')
PYTHON    ?= python3
INJECT    := scripts/inject.py
ROOT      := $(abspath .)
PK3_NAME  := gt_warfork_extended_$(VERSION).pk3
GO        ?= go
GO_DIR    := $(ROOT)/tools/report-notify
GO_BIN    := we-report-notify
GO_OUT    := $(ROOT)/dist/go
PREFIX    ?= /opt/we-report-notify
GO_LDFLAGS := -ldflags "-X main.version=$(VERSION)"

# Optional: overlay gamemodes/custom (or CUSTOM_ROOT) into the WE pk3 for local debug.
INCLUDE_CUSTOM ?= 0
# make custom: required CUSTOM_ROOT + PK3; optional MODE=prod|debug
MODE ?= prod

.DEFAULT_GOAL := help

.PHONY: help dev prod clean inject-dev inject-prod pack-dev pack-prod install-dev custom go go-release go-install

help:
	@echo "warfork-extended $(VERSION)"
	@echo ""
	@echo "Targets:"
	@echo "  make help        Show this help (default)"
	@echo "  make dev         Inject (debug), pack pk3, copy to WARFORK_BASEWF"
	@echo "  make prod        Inject (prod), pack pk3 under dist/prod/"
	@echo "  make custom CUSTOM_ROOT=<gt-repo> PK3=<out.pk3>  Thin custom-GT pk3"
	@echo "  make go          Build report-notify binary -> dist/go/"
	@echo "  make go-release  Linux amd64 report-notify (CI / release asset)"
	@echo "  make go-install  Install binary + example config to PREFIX"
	@echo "  make clean       Remove dist/ and local *.pk3"
	@echo ""
	@echo "Options:"
	@echo "  INCLUDE_CUSTOM=1  Overlay gamemodes/custom (or CUSTOM_ROOT) into WE pk3"
	@echo "  MODE=prod|debug   Inject mode for make custom (default: prod)"
	@echo "  PREFIX=$(PREFIX)  Install path for make go-install"
	@echo ""
	@echo "Config: copy config.mk.example -> config.mk"
	@echo "  WARFORK_BASEWF=$(WARFORK_BASEWF)"

INJECT_EXTRA :=
ifeq ($(INCLUDE_CUSTOM),1)
INJECT_EXTRA += --include-custom
ifdef CUSTOM_ROOT
INJECT_EXTRA += --custom-root $(CUSTOM_ROOT)
endif
endif

inject-dev:
	$(PYTHON) $(INJECT) --mode debug --root $(ROOT) --out $(ROOT)/dist/debug $(INJECT_EXTRA)

inject-prod:
	$(PYTHON) $(INJECT) --mode prod --root $(ROOT) --out $(ROOT)/dist/prod $(INJECT_EXTRA)

pack-dev: inject-dev
	@rm -f $(ROOT)/dist/debug/$(PK3_NAME)
	cd $(ROOT)/dist/debug && zip -r $(PK3_NAME) progs
	@echo "Built dist/debug/$(PK3_NAME)"

pack-prod: inject-prod
	@rm -f $(ROOT)/dist/prod/$(PK3_NAME)
	cd $(ROOT)/dist/prod && zip -r $(PK3_NAME) progs
	@echo "Built dist/prod/$(PK3_NAME)"

install-dev: pack-dev
ifndef WARFORK_BASEWF
	$(error WARFORK_BASEWF not set. Copy config.mk.example to config.mk)
endif
	@mkdir -p "$(WARFORK_BASEWF)"
	@rm -f "$(WARFORK_BASEWF)"/gt_warfork_extended_*.pk3
	cp -f "$(ROOT)/dist/debug/$(PK3_NAME)" "$(WARFORK_BASEWF)/$(PK3_NAME)"
	@echo "Installed $(PK3_NAME) -> $(WARFORK_BASEWF)/"

dev: install-dev

prod: pack-prod

# Thin custom gametype pk3 (depends on WE pk3 on the server for warfork-extended/* + we_*).
custom:
ifndef CUSTOM_ROOT
	$(error CUSTOM_ROOT not set. Example: make custom CUSTOM_ROOT=/path/to/my-gt PK3=/path/to/gt_mygt.pk3)
endif
ifndef PK3
	$(error PK3 not set. Example: make custom CUSTOM_ROOT=/path/to/my-gt PK3=/path/to/gt_mygt.pk3)
endif
	@case "$(MODE)" in prod|debug) ;; *) echo "MODE must be prod or debug (got: $(MODE))"; exit 1 ;; esac
	$(PYTHON) $(INJECT) --mode $(MODE) --root $(ROOT) \
		--custom-root "$(CUSTOM_ROOT)" --out $(ROOT)/dist/custom
	@mkdir -p "$$(dirname "$(PK3)")"
	@rm -f "$(PK3)"
	@abs_pk3=$$(cd "$$(dirname "$(PK3)")" && pwd)/$$(basename "$(PK3)"); \
		cd $(ROOT)/dist/custom && zip -r "$$abs_pk3" progs
	@echo "Built $(PK3) (MODE=$(MODE); requires WE pk3 on server)"

go:
	@mkdir -p "$(GO_OUT)"
	cd "$(GO_DIR)" && $(GO) build $(GO_LDFLAGS) -o "$(GO_OUT)/$(GO_BIN)" .
	@echo "Built $(GO_OUT)/$(GO_BIN)"

go-release:
	@mkdir -p "$(GO_OUT)"
	cd "$(GO_DIR)" && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		$(GO) build $(GO_LDFLAGS) -o "$(GO_OUT)/$(GO_BIN)-linux-amd64" .
	@echo "Built $(GO_OUT)/$(GO_BIN)-linux-amd64"

go-install: go
	@mkdir -p "$(PREFIX)"
	cp -f "$(GO_OUT)/$(GO_BIN)" "$(PREFIX)/$(GO_BIN)"
	@if [ ! -f "$(PREFIX)/config.yaml" ]; then \
		cp "$(GO_DIR)/config.yaml.example" "$(PREFIX)/config.yaml"; \
		echo "Installed example config -> $(PREFIX)/config.yaml (edit before use)"; \
	else \
		echo "Keeping existing $(PREFIX)/config.yaml"; \
	fi
	@echo "Installed $(PREFIX)/$(GO_BIN)"
	@echo "Cron: see $(GO_DIR)/crontab.example (use -once every minute)"

clean:
	rm -rf dist
	rm -f gt_warfork_extended_*.pk3
