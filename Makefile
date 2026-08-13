# warfork-extended — type `make` for help

-include config.mk

VERSION   := $(shell cat VERSION 2>/dev/null | tr -d '[:space:]')
PYTHON    ?= python3
INJECT    := scripts/inject.py
ROOT      := $(abspath .)
PK3_NAME  := gt_warfork_extended_$(VERSION).pk3

.DEFAULT_GOAL := help

.PHONY: help dev prod clean inject-dev inject-prod pack-dev pack-prod install-dev

help:
	@echo "warfork-extended $(VERSION)"
	@echo ""
	@echo "Targets:"
	@echo "  make help   Show this help (default)"
	@echo "  make dev    Inject (debug), pack pk3, copy to WARFORK_BASEWF"
	@echo "  make prod   Inject (prod), pack pk3 under dist/prod/"
	@echo "  make clean  Remove dist/ and local *.pk3"
	@echo ""
	@echo "Config: copy config.mk.example -> config.mk"
	@echo "  WARFORK_BASEWF=$(WARFORK_BASEWF)"

inject-dev:
	$(PYTHON) $(INJECT) --mode debug --root $(ROOT) --out $(ROOT)/dist/debug

inject-prod:
	$(PYTHON) $(INJECT) --mode prod --root $(ROOT) --out $(ROOT)/dist/prod

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

clean:
	rm -rf dist
	rm -f gt_warfork_extended_*.pk3
