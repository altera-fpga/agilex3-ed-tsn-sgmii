# Standalone VDS/UVM verification Makefile (parallel to ITF/reg_exe).
# Usage:
#   source env/env.sh && source env/setup.sh
#   make env
#   make generate
#   make compile
#   make sim
#   make regress

SHELL := /bin/bash
VERIF_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS    := $(VERIF_ROOT)/scripts
WORK_DIR   := $(VERIF_ROOT)/work

.PHONY: help env generate compile sim regress clean clobber

help:
	@echo "Targets: env generate compile sim regress clean clobber"
	@echo "Knobs: TEST SEQ SEED NUM_SEEDS VERBOSITY ERROR_COUNT DUMP XPROP SIM_TIMEOUT REGR_LIST STRICT_UNSUPPORTED PLUSARGS"

env:
	@$(SCRIPTS)/check_env.sh

generate:
	@$(SCRIPTS)/generate_dut.sh

compile:
	@$(SCRIPTS)/compile.sh

sim:
	@$(SCRIPTS)/run_sim.sh

regress:
	@$(SCRIPTS)/run_regress.sh

# Guarded deletes: only under $(VERIF_ROOT)/work
clean:
	@abs="$(WORK_DIR)"; \
	case "$$abs" in \
	  "$(VERIF_ROOT)/work") ;; \
	  *) echo "ERROR: refusing clean outside verification/work: $$abs" >&2; exit 1 ;; \
	esac; \
	rm -f "$$abs/simv" "$$abs/compile_fingerprint.json"; \
	rm -rf "$$abs/logs"; mkdir -p "$$abs/logs"; \
	if [[ -f "$$abs/vcsmx_paths.env" ]]; then \
	  source "$$abs/vcsmx_paths.env"; \
	  if [[ -n "$${VCSMX_DIR:-}" && -d "$${VCSMX_DIR}" ]]; then \
	    case "$${VCSMX_DIR}" in \
	      "$(VERIF_ROOT)/work"/*) \
	        rm -rf "$${VCSMX_DIR}/simv" "$${VCSMX_DIR}/simv.daidir" "$${VCSMX_DIR}/csrc" "$${VCSMX_DIR}/AN.DB" ;; \
	    esac; \
	  fi; \
	fi; \
	echo "clean: compile/sim artifacts under $$abs"

clobber:
	@abs="$(WORK_DIR)"; \
	case "$$abs" in \
	  "$(VERIF_ROOT)/work") ;; \
	  *) echo "ERROR: refusing clobber outside verification/work: $$abs" >&2; exit 1 ;; \
	esac; \
	rm -rf "$$abs"/*; \
	mkdir -p "$$abs/logs"; \
	echo "clobber: removed contents of $$abs"
