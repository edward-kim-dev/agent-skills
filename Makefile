SHELL := /bin/bash
ROOT  := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)

# ─────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────
SKILL_DIR       = .claude/skills
GLOBAL_SKILL_DIR = $(HOME)/.claude/skills

# ─────────────────────────────────────────────
# Helper: find all skill directories (containing SKILL.md)
# ─────────────────────────────────────────────
FIND_SKILLS = find "$(ROOT)/sources" -mindepth 3 -maxdepth 3 -name "SKILL.md" -exec dirname {} \; 2>/dev/null | sort

# ─────────────────────────────────────────────
# Info
# ─────────────────────────────────────────────

.PHONY: help list status

help: ## Show this help
	@echo "AgentSkills - AI 스킬 중앙 관리"
	@echo ""
	@echo "Usage: make <target> [OPTIONS]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

list: ## List available skill packs and their skills
	@for pack in $(ROOT)/sources/*/; do \
		name=$$(basename "$$pack"); \
		skills=$$(find "$$pack" -mindepth 2 -maxdepth 2 -name "SKILL.md" -exec dirname {} \; 2>/dev/null | xargs -I{} basename {} | sort | tr '\n' ', ' | sed 's/,$$//'); \
		[ -n "$$skills" ] && echo "  $$name: $$skills"; \
	done

status: ## Show current deployment status
	@for pack in $(ROOT)/sources/*/; do \
		name=$$(basename "$$pack"); \
		count=$$(find "$$pack" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' '); \
		echo "  $$name ($$count skills)"; \
	done

# ─────────────────────────────────────────────
# Deploy
# ─────────────────────────────────────────────

.PHONY: deploy deploy-global

deploy: ## Deploy skills to PROJECT (make deploy PROJECT=/path)
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required. Usage: make deploy PROJECT=/path/to/project"; exit 1; fi
	@mkdir -p "$(PROJECT)/$(SKILL_DIR)"
	@$(FIND_SKILLS) | while read skill_dir; do \
		name=$$(basename "$$skill_dir"); \
		target="$(PROJECT)/$(SKILL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$$skill_dir" "$$target"; \
			echo "  link: $$name"; \
		fi; \
	done
	@echo "Done: skills deployed to $(PROJECT)/.claude/skills/"

deploy-global: ## Deploy skills to ~/.claude/skills/
	@mkdir -p "$(GLOBAL_SKILL_DIR)"
	@$(FIND_SKILLS) | while read skill_dir; do \
		name=$$(basename "$$skill_dir"); \
		target="$(GLOBAL_SKILL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$$skill_dir" "$$target"; \
			echo "  link: $$name"; \
		fi; \
	done
	@echo "Done: skills installed globally"

# ─────────────────────────────────────────────
# Undeploy
# ─────────────────────────────────────────────

.PHONY: undeploy undeploy-global

undeploy: ## Remove deployed skills from PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required."; exit 1; fi
	@if [ -d "$(PROJECT)/$(SKILL_DIR)" ]; then \
		find "$(PROJECT)/$(SKILL_DIR)" -maxdepth 1 -type l | while read link; do \
			target=$$(readlink "$$link"); \
			if echo "$$target" | grep -q "$(ROOT)/sources/"; then \
				rm "$$link"; echo "  removed: $$(basename $$link)"; \
			fi; \
		done; \
	fi

undeploy-global: ## Remove deployed skills from ~/.claude/skills/
	@if [ -d "$(GLOBAL_SKILL_DIR)" ]; then \
		find "$(GLOBAL_SKILL_DIR)" -maxdepth 1 -type l | while read link; do \
			target=$$(readlink "$$link"); \
			if echo "$$target" | grep -q "$(ROOT)/sources/"; then \
				rm "$$link"; echo "  removed: $$(basename $$link)"; \
			fi; \
		done; \
	fi

# ─────────────────────────────────────────────
# Source management
# ─────────────────────────────────────────────

.PHONY: add-source remove-source

add-source: ## Add a new skill pack source (make add-source NAME=my-pack URL=https://...)
	@if [ -z "$(NAME)" ] || [ -z "$(URL)" ]; then \
		echo "Usage: make add-source NAME=<name> URL=<git-url>"; exit 1; fi
	@if [ -d "$(ROOT)/sources/$(NAME)" ]; then \
		echo "Error: source '$(NAME)' already exists"; exit 1; fi
	git submodule add "$(URL)" "$(ROOT)/sources/$(NAME)"
	@echo "Done: Added source '$(NAME)'"

remove-source: ## Remove a skill pack source (make remove-source NAME=my-pack)
	@if [ -z "$(NAME)" ]; then echo "Usage: make remove-source NAME=<name>"; exit 1; fi
	@if git submodule status "sources/$(NAME)" >/dev/null 2>&1; then \
		git submodule deinit -f "sources/$(NAME)"; \
		git rm -f "sources/$(NAME)"; \
		rm -rf ".git/modules/sources/$(NAME)"; \
		echo "  removed submodule: sources/$(NAME)"; \
	elif [ -d "$(ROOT)/sources/$(NAME)" ]; then \
		rm -rf "$(ROOT)/sources/$(NAME)"; \
		echo "  removed directory: sources/$(NAME)"; \
	fi
	@echo "Done: Removed source '$(NAME)'"
