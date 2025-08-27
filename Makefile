STOW_DIR := configs
TARGET   := $(HOME)
# Auto-discover package names under configs/
PACKAGES := $(shell find $(STOW_DIR) -mindepth 1 -maxdepth 1 -type d -printf "%f ")

.PHONY: help list dry-run apply apply-% delete delete-% doctor

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_%-]+:.*?## ' Makefile | awk 'BEGIN{FS=":.*?## "}{printf "%-14s %s\n", $$1, $$2}'

list: ## List discovered packages
	@echo "Packages:" $(PACKAGES)

dry-run: ## Show what would be linked and summarize conflicts
	@echo "== Dry run (full logs) =="; \
	for p in $(PACKAGES); do \
	  echo ""; echo "== [$$p] =="; \
	  stow -n -v -d $(STOW_DIR) -t $(TARGET) $$p || true; \
	done; \
	echo ""; echo "== Conflict summary =="; \
	for p in $(PACKAGES); do \
	  stow -n -v -d $(STOW_DIR) -t $(TARGET) $$p 2>&1 | grep -E 'BUG:|WARNING|CONFLICT|existing' && echo "" || true; \
	done

apply: ## Apply all packages
	stow -v -d $(STOW_DIR) -t $(TARGET) $(PACKAGES)

apply-%: ## Apply a single package, e.g. `make apply-nvim`
	@test -d "$(STOW_DIR)/$*" || (echo "ERROR: package '$*' not found under $(STOW_DIR)"; exit 1)
	stow -v -d $(STOW_DIR) -t $(TARGET) $*

delete: ## Unstow all packages
	stow -D -d $(STOW_DIR) -t $(TARGET) $(PACKAGES)

delete-%: ## Unstow a single package, e.g. `make delete-nvim`
	@test -d "$(STOW_DIR)/$*" || (echo "ERROR: package '$*' not found under $(STOW_DIR)"; exit 1)
	stow -D -d $(STOW_DIR) -t $(TARGET) $*

doctor: ## Find broken symlinks in $HOME
	find $(TARGET) -xtype l -print