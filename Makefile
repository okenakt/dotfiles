STOW_DIR    := configs
TARGET      := ${HOME}
BACKUP_ROOT := backups
BACKUP_DIR  := ${BACKUP_ROOT}/$(shell date +%Y%m%d%H%M%S)
PACKAGES    := $(shell find ${STOW_DIR} -mindepth 1 -maxdepth 1 -type d -printf "%f ")
pkg         ?=
pkgs         = $(if ${pkg},${pkg},${PACKAGES})

.PHONY: help list dry-run backup prepare restore apply delete doctor

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_%-]+:.*?## ' Makefile | awk 'BEGIN{FS=":.*?## "}{printf "%-18s %s\n", $$1, $$2}'

list: ## List discovered packages
	@echo "Packages:" ${PACKAGES}

dry-run: ## Show what would be linked (set pkg=<name> to limit)
	@echo "== Dry run =="; \
	for p in ${pkgs}; do \
	  echo ""; echo "[$$p]"; \
	  stow -n -v -d ${STOW_DIR} -t ${TARGET} $$p || true; \
	done

backup: ## Back up existing files that would be replaced (set pkg=<name> to limit)
	@mkdir -p ${BACKUP_DIR}; \
	echo "Backup dir: ${BACKUP_DIR}"; \
	for p in ${pkgs}; do \
	  pkg_root="${STOW_DIR}/$$p"; \
	  [ -d "$$pkg_root" ] || { echo "ERROR: package '$$p' not found"; exit 1; }; \
	  files=$$(cd "$$pkg_root" && find . \( -type f -o -type l \) -print | sed 's|^\./||'); \
	  saved=0; \
	  for rel in $$files; do \
	    [ -n "$$rel" ] || continue; \
	    source_path="$$pkg_root/$$rel"; \
	    target_path="${TARGET}/$$rel"; \
	    if [ -e "$$target_path" ] || [ -L "$$target_path" ]; then \
	      source_real=$$(realpath -e "$$source_path" 2>/dev/null || true); \
	      target_real=$$(realpath -e "$$target_path" 2>/dev/null || true); \
	      if [ -n "$$source_real" ] && [ "$$source_real" = "$$target_real" ]; then continue; fi; \
	      mkdir -p "${BACKUP_DIR}/$$p"; \
	      rsync -aR "${TARGET}/./$$rel" "${BACKUP_DIR}/$$p/" >/dev/null 2>&1; \
	      echo "saved: $$target_path"; \
	      saved=1; \
	    fi; \
	  done; \
	  if [ "$$saved" -eq 0 ]; then echo "no existing files for $$p"; fi; \
	done

prepare: backup ## Prepare target files for Stow by removing backed-up conflicts (set pkg=<name> to limit)
	@for p in ${pkgs}; do \
	  pkg_root="${STOW_DIR}/$$p"; \
	  [ -d "$$pkg_root" ] || { echo "ERROR: package '$$p' not found"; exit 1; }; \
	  files=$$(cd "$$pkg_root" && find . \( -type f -o -type l \) -print | sed 's|^\./||'); \
	  removed=0; \
	  for rel in $$files; do \
	    [ -n "$$rel" ] || continue; \
	    source_path="$$pkg_root/$$rel"; \
	    target_path="${TARGET}/$$rel"; \
	    backup_path="${BACKUP_DIR}/$$p/$$rel"; \
	    if [ ! -e "$$target_path" ] && [ ! -L "$$target_path" ]; then continue; fi; \
	    source_real=$$(realpath -e "$$source_path" 2>/dev/null || true); \
	    target_real=$$(realpath -e "$$target_path" 2>/dev/null || true); \
	    if [ -n "$$source_real" ] && [ "$$source_real" = "$$target_real" ]; then continue; fi; \
	    if [ -d "$$target_path" ] && [ ! -L "$$target_path" ]; then \
	      echo "ERROR: refusing to remove directory: $$target_path"; \
	      exit 1; \
	    fi; \
	    if [ ! -e "$$backup_path" ] && [ ! -L "$$backup_path" ]; then \
	      echo "ERROR: backup missing for $$target_path"; \
	      exit 1; \
	    fi; \
	    rm -f "$$target_path"; \
	    echo "removed: $$target_path -> $$backup_path"; \
	    removed=1; \
	  done; \
	  if [ "$$removed" -eq 0 ]; then echo "no files to prepare for $$p"; fi; \
	done

restore: ## Restore backed up files into ${TARGET}; set backup=<dir> and optional pkg=<name>
	@test -n "${backup}" || { echo "ERROR: backup=<dir> must be provided"; exit 1; }
	@for p in ${pkgs}; do \
	  backup_arg="${backup}"; \
	  case "$$backup_arg" in \
	    /*) backup_base="$$backup_arg";; \
	    ${BACKUP_ROOT}/*) backup_base="$$backup_arg";; \
	    *) backup_base="${BACKUP_ROOT}/$$backup_arg";; \
	  esac; \
	  backup_dir="$$backup_base/$$p"; \
	  if [ ! -d "$$backup_dir" ]; then echo "skip $$p (no backup in $$backup_base)"; continue; fi; \
	  echo "restore $$p from $$backup_base"; \
	  rsync -a "$$backup_dir/" "${TARGET}/" || exit $$?; \
	done

apply: prepare ## Back up, prepare targets, and apply packages (set pkg=<name> to limit)
	stow -R -v -d ${STOW_DIR} -t ${TARGET} ${pkgs}

delete: ## Unstow packages (set pkg=<name> to limit)
	stow -D -d ${STOW_DIR} -t ${TARGET} ${pkgs}

doctor: ## Find broken symlinks in $HOME
	find ${TARGET} -xtype l -print
