STOW_DIR    := configs
TARGET      := ${HOME}
BACKUP_ROOT := backups
BACKUP_DIR  := ${BACKUP_ROOT}/$(shell date +%Y%m%d%H%M%S)
PACKAGES    := $(shell find ${STOW_DIR} -mindepth 1 -maxdepth 1 -type d -printf "%f ")
pkg         ?=
pkgs         = $(if ${pkg},${pkg},${PACKAGES})

.PHONY: help list dry-run backup backup-one prune prune-one restore restore-one apply delete doctor

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_%-]+:.*?## ' Makefile | awk 'BEGIN{FS=":.*?## "}{printf "%-14s %s\n", $$1, $$2}'

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
	  ${MAKE} --no-print-directory BACKUP_DIR=${BACKUP_DIR} pkg=$$p backup-one || exit $$?; \
	done

backup-one:
	@pkg="${pkg}"; \
	[ -n "$$pkg" ] || exit 0; \
	pkg_root="${STOW_DIR}/$$pkg"; \
	[ -d "$$pkg_root" ] || { echo "ERROR: package '$$pkg' not found"; exit 1; }; \
	files=$$(cd "$$pkg_root" && find . \( -type f -o -type l \) -print | sed 's|^\./||'); \
	saved=0; \
	for rel in $$files; do \
	  [ -n "$$rel" ] || continue; \
	  target_path="${TARGET}/$$rel"; \
	  if [ -e "$$target_path" ] || [ -L "$$target_path" ]; then \
	    mkdir -p "${BACKUP_DIR}/$$pkg"; \
	    rsync -aR "${TARGET}/./$$rel" "${BACKUP_DIR}/$$pkg/" >/dev/null 2>&1; \
	    echo "saved: $$target_path"; \
	    saved=1; \
	  fi; \
	done; \
	if [ "$$saved" -eq 0 ]; then echo "no existing files for $$pkg"; fi

prune: ## Remove existing files in ${TARGET} before applying (set pkg=<name> to limit)
	@for p in ${pkgs}; do \
	  ${MAKE} --no-print-directory pkg=$$p prune-one || exit $$?; \
	done

prune-one:
	@pkg="${pkg}"; \
	[ -n "$$pkg" ] || exit 0; \
	pkg_root="${STOW_DIR}/$$pkg"; \
	[ -d "$$pkg_root" ] || { echo "ERROR: package '$$pkg' not found"; exit 1; }; \
	paths=$$(cd "$$pkg_root" && find . \( -type f -o -type l \) -print | sed 's|^\./||'); \
	for rel in $$paths; do \
	  [ -n "$$rel" ] || continue; \
	  target_path="${TARGET}/$$rel"; \
	  if [ -e "$$target_path" ] || [ -L "$$target_path" ]; then \
	    rm -f -- "$$target_path"; \
	    echo "removed: $$target_path"; \
	  fi; \
	done

restore: ## Restore backed up files into ${TARGET}; set backup=<dir> and optional pkg=<name>
	@test -n "${backup}" || { echo "ERROR: backup=<dir> must be provided"; exit 1; }
	@for p in ${pkgs}; do \
	  ${MAKE} --no-print-directory pkg=$$p backup=${backup} restore-one || exit $$?; \
	done

restore-one:
	@pkg="${pkg}"; backup_arg="${backup}"; \
	[ -n "$$pkg" ] || { echo "ERROR: PKG not set"; exit 1; }; \
	[ -n "$$backup_arg" ] || { echo "ERROR: backup not set"; exit 1; }; \
	case "$$backup_arg" in \
	  /*) backup_base="$$backup_arg";; \
	  ${BACKUP_ROOT}/*) backup_base="$$backup_arg";; \
	  *) backup_base="${BACKUP_ROOT}/$$backup_arg";; \
	esac; \
	backup_dir="$$backup_base/$$pkg"; \
	if [ ! -d "$$backup_dir" ]; then echo "skip $$pkg (no backup in $$backup_base)"; exit 0; fi; \
	echo "restore $$pkg from $$backup_base"; \
	rsync -a "$$backup_dir/" "${TARGET}/"

apply: backup ## Apply packages (set pkg=<name> to limit)
	@${MAKE} --no-print-directory pkg="${pkg}" prune
	stow -v -d ${STOW_DIR} -t ${TARGET} ${pkgs}

delete: ## Unstow packages (set pkg=<name> to limit)
	stow -D -d ${STOW_DIR} -t ${TARGET} ${pkgs}

doctor: ## Find broken symlinks in $HOME
	find ${TARGET} -xtype l -print
