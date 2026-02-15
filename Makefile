SHELL := /bin/bash
ROOT  := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)

# ─────────────────────────────────────────────
# Tool paths (where each AI tool reads skills)
# ─────────────────────────────────────────────
CURSOR_SKILL_DIR     = .cursor/skills
CLAUDE_SKILL_DIR     = .claude/skills
CODEX_SKILL_DIR      = .agents/skills
CLAUDE_GLOBAL_DIR    = $(HOME)/.claude/skills
CODEX_GLOBAL_DIR     = $(HOME)/.agents/skills

# ─────────────────────────────────────────────
# Info
# ─────────────────────────────────────────────

.PHONY: help list status

help: ## Show this help
	@echo "AgentSkills - AI 도구 스킬 중앙 관리"
	@echo ""
	@echo "Usage: make <target> [OPTIONS]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

list: ## List available skill packs and their skills
	@echo "=== Skill Packs ==="
	@for pack in $(ROOT)/sources/*/; do \
		name=$$(basename "$$pack"); \
		skills=$$(ls -d "$$pack"/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$$//'); \
		echo "  $$name: $$skills"; \
	done
	@echo ""
	@echo "=== Custom Skills ==="
	@if ls $(ROOT)/custom/*/SKILL.md 1>/dev/null 2>&1; then \
		for skill in $(ROOT)/custom/*/SKILL.md; do \
			echo "  $$(basename $$(dirname $$skill))"; \
		done; \
	else \
		echo "  (none)"; \
	fi

status: ## Show current deployment status
	@echo "=== Source Packs ==="
	@for pack in $(ROOT)/sources/*/; do \
		name=$$(basename "$$pack"); \
		count=$$(ls -d "$$pack"/*/ 2>/dev/null | wc -l | tr -d ' '); \
		echo "  $$name ($$count skills)"; \
	done
	@echo ""
	@echo "=== Tool Links ==="
	@for tool in cursor claude-code codex; do \
		echo "  $$tool:"; \
		for link in $(ROOT)/$$tool/*/; do \
			name=$$(basename "$$link"); \
			if [ -L "$(ROOT)/$$tool/$$name" ]; then \
				target=$$(readlink "$(ROOT)/$$tool/$$name"); \
				echo "    $$name -> $$target"; \
			fi; \
		done; \
	done

# ─────────────────────────────────────────────
# Deploy to project
# ─────────────────────────────────────────────

.PHONY: deploy-cursor deploy-claude deploy-codex deploy-all

deploy-cursor: ## Deploy Cursor skills to PROJECT (make deploy-cursor PROJECT=/path)
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required. Usage: make deploy-cursor PROJECT=/path/to/project"; exit 1; fi
	@mkdir -p "$(PROJECT)/$(CURSOR_SKILL_DIR)"
	@for skill in $(ROOT)/cursor/*/; do \
		name=$$(basename "$$skill"); \
		src=$$(cd "$$skill" && pwd -P); \
		target="$(PROJECT)/$(CURSOR_SKILL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$$src" "$$target"; \
			echo "  link: $$name"; \
		fi; \
	done
	@echo "Done: Cursor skills deployed to $(PROJECT)"

deploy-claude: ## Deploy Claude Code skills to PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required. Usage: make deploy-claude PROJECT=/path/to/project"; exit 1; fi
	@mkdir -p "$(PROJECT)/$(CLAUDE_SKILL_DIR)"
	@for pack in $(ROOT)/claude-code/*/; do \
		name=$$(basename "$$pack"); \
		target="$(PROJECT)/$(CLAUDE_SKILL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$(ROOT)/sources/$$name" "$$target"; \
			echo "  link: $$name -> $$target"; \
		fi; \
	done
	@echo "Done: Claude Code skills deployed to $(PROJECT)"

deploy-codex: ## Deploy Codex skills to PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required. Usage: make deploy-codex PROJECT=/path/to/project"; exit 1; fi
	@mkdir -p "$(PROJECT)/$(CODEX_SKILL_DIR)"
	@for pack in $(ROOT)/codex/*/; do \
		name=$$(basename "$$pack"); \
		target="$(PROJECT)/$(CODEX_SKILL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$(ROOT)/sources/$$name" "$$target"; \
			echo "  link: $$name -> $$target"; \
		fi; \
	done
	@echo "Done: Codex skills deployed to $(PROJECT)"

deploy-all: ## Deploy all tools to PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required."; exit 1; fi
	@$(MAKE) deploy-cursor PROJECT="$(PROJECT)"
	@$(MAKE) deploy-claude PROJECT="$(PROJECT)"
	@$(MAKE) deploy-codex  PROJECT="$(PROJECT)"

# ─────────────────────────────────────────────
# Deploy globally
# ─────────────────────────────────────────────

.PHONY: deploy-claude-global deploy-codex-global

deploy-claude-global: ## Deploy Claude Code skills to ~/.claude/skills/
	@mkdir -p "$(CLAUDE_GLOBAL_DIR)"
	@for pack in $(ROOT)/claude-code/*/; do \
		name=$$(basename "$$pack"); \
		target="$(CLAUDE_GLOBAL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$(ROOT)/sources/$$name" "$$target"; \
			echo "  link: $$name -> $$target"; \
		fi; \
	done
	@echo "Done: Claude Code skills installed globally"

deploy-codex-global: ## Deploy Codex skills to ~/.agents/skills/
	@mkdir -p "$(CODEX_GLOBAL_DIR)"
	@for pack in $(ROOT)/codex/*/; do \
		name=$$(basename "$$pack"); \
		target="$(CODEX_GLOBAL_DIR)/$$name"; \
		if [ -e "$$target" ]; then \
			echo "  skip: $$name (already exists)"; \
		else \
			ln -s "$(ROOT)/sources/$$name" "$$target"; \
			echo "  link: $$name -> $$target"; \
		fi; \
	done
	@echo "Done: Codex skills installed globally"

# ─────────────────────────────────────────────
# Undeploy
# ─────────────────────────────────────────────

.PHONY: undeploy-cursor undeploy-claude undeploy-codex

undeploy-cursor: ## Remove deployed Cursor skills from PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required."; exit 1; fi
	@for skill in $(ROOT)/cursor/*/; do \
		name=$$(basename "$$skill"); \
		target="$(PROJECT)/$(CURSOR_SKILL_DIR)/$$name"; \
		if [ -L "$$target" ]; then rm "$$target"; echo "  removed: $$name"; fi; \
	done

undeploy-claude: ## Remove deployed Claude Code skills from PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required."; exit 1; fi
	@for pack in $(ROOT)/claude-code/*/; do \
		name=$$(basename "$$pack"); \
		target="$(PROJECT)/$(CLAUDE_SKILL_DIR)/$$name"; \
		if [ -L "$$target" ]; then rm "$$target"; echo "  removed: $$target"; fi; \
	done

undeploy-codex: ## Remove deployed Codex skills from PROJECT
	@if [ -z "$(PROJECT)" ]; then echo "Error: PROJECT required."; exit 1; fi
	@for pack in $(ROOT)/codex/*/; do \
		name=$$(basename "$$pack"); \
		target="$(PROJECT)/$(CODEX_SKILL_DIR)/$$name"; \
		if [ -L "$$target" ]; then rm "$$target"; echo "  removed: $$target"; fi; \
	done

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
	@# Claude Code / Codex: pack-level link
	@for tool in claude-code codex; do \
		ln -s "../sources/$(NAME)" "$(ROOT)/$$tool/$(NAME)"; \
		echo "  linked: $$tool/$(NAME)"; \
	done
	@# Cursor: individual skill links (flat structure required)
	@for skill in $(ROOT)/sources/$(NAME)/*/; do \
		sname=$$(basename "$$skill"); \
		if [ -f "$$skill/SKILL.md" ]; then \
			ln -s "../sources/$(NAME)/$$sname" "$(ROOT)/cursor/$$sname"; \
			echo "  linked: cursor/$$sname"; \
		fi; \
	done
	@echo "Done: Added source '$(NAME)'"

remove-source: ## Remove a skill pack source (make remove-source NAME=my-pack)
	@if [ -z "$(NAME)" ]; then echo "Usage: make remove-source NAME=<name>"; exit 1; fi
	@# Claude Code / Codex: remove pack-level link
	@for tool in claude-code codex; do \
		link="$(ROOT)/$$tool/$(NAME)"; \
		if [ -L "$$link" ]; then rm "$$link"; echo "  unlinked: $$tool/$(NAME)"; fi; \
	done
	@# Cursor: remove individual skill links pointing into this source
	@for link in $(ROOT)/cursor/*/; do \
		name=$$(basename "$$link"); \
		if [ -L "$(ROOT)/cursor/$$name" ]; then \
			target=$$(readlink "$(ROOT)/cursor/$$name"); \
			if echo "$$target" | grep -q "sources/$(NAME)/"; then \
				rm "$(ROOT)/cursor/$$name"; \
				echo "  unlinked: cursor/$$name"; \
			fi; \
		fi; \
	done
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
