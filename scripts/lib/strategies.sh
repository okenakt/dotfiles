#!/usr/bin/env bash
# Typed installers shared by install.sh.
#
# Callers declare what to install; a strategy owns how. Every strategy is
# idempotent, honours FORCE, dies on failure and verifies its own result.
#
# Each strategy returns 0 and sets CHANGED to 1 when it did work, or 0 when it
# skipped an up-to-date install. Callers that have follow-up work to do (a cache
# to refresh, say) branch on CHANGED; the rest can ignore it.

FORCE=0
CHANGED=0
LOG_TAG="install"
TMP_DIR=""

log() {
  printf '[%s] %s\n' "$LOG_TAG" "$1"
}

warn() {
  printf '[%s] warning: %s\n' "$LOG_TAG" "$1" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$LOG_TAG" "$1" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# One scratch directory per run, created on first use so a run that installs
# nothing never makes one. Sets TMP_DIR rather than printing it: called through
# a command substitution, both the mktemp and the trap would land in a subshell
# whose exit would delete the directory again.
ensure_tmp_dir() {
  [ -z "$TMP_DIR" ] || return 0
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
}

fetch() {
  curl -fsSL --retry 3 -o "$2" "$1" || die "failed to download $1"
}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

package_version() {
  dpkg-query -W -f='${Version}' "$1" 2>/dev/null
}

# Upstream archives carry no version metadata, so record the pinned version
# next to the install and use it as the skip condition on the next run.
stamp_matches() {
  [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]
}

need_value() {
  [ "$2" -ge 2 ] || die "$1 requires a value"
}

# --- strategy: apt --------------------------------------------------------
# Install packages with apt. Everything apt can already see needs no more than
# --package; the optional flags cover the two ways a package has to be made
# visible to apt first:
#
#   --deb-url   the official .deb configures its own repo from its postinst, so
#               fetching it once and letting apt install the file is the whole
#               job. Adding the repo by hand first would only be overwritten.
#   --key-url   no such hook exists, so the keyring and sources line have to be
#     + friends laid down before apt can see the package at all.
#
# --sources names the file the install is expected to leave behind. apt taking
# over from here is the point of both routes; without it upgrades never arrive.
apt_install() {
  local -a packages=() targets=() missing=() split=()
  local deb_url="" key_url="" keyring="" sources="" repo_line="" p

  while [ $# -gt 0 ]; do
    case "$1" in
      --package)  need_value "$1" $#; packages+=("$2"); shift 2 ;;
      --packages) need_value "$1" $#; read -ra split <<<"$2"; packages+=("${split[@]}"); shift 2 ;;
      --deb-url)  need_value "$1" $#; deb_url="$2"; shift 2 ;;
      --key-url)  need_value "$1" $#; key_url="$2"; shift 2 ;;
      --keyring)  need_value "$1" $#; keyring="$2"; shift 2 ;;
      --sources)  need_value "$1" $#; sources="$2"; shift 2 ;;
      --repo)     need_value "$1" $#; repo_line="$2"; shift 2 ;;
      *)          die "apt_install: unknown option: $1" ;;
    esac
  done
  [ "${#packages[@]}" -gt 0 ] || die "apt_install: --package is required"

  for p in "${packages[@]}"; do
    package_installed "$p" || missing+=("$p")
  done

  if [ "$FORCE" -eq 0 ] && [ "${#missing[@]}" -eq 0 ]; then
    if [ "${#packages[@]}" -eq 1 ]; then
      log "${packages[0]} $(package_version "${packages[0]}") already installed, skipping"
    else
      log "all ${#packages[@]} packages already installed"
    fi
    CHANGED=0
    return 0
  fi

  if [ "$FORCE" -eq 1 ]; then
    targets=("${packages[@]}")
    log "reinstalling ${#targets[@]} package(s)"
  else
    targets=("${missing[@]}")
    log "${#targets[@]} of ${#packages[@]} package(s) missing: ${targets[*]}"
  fi

  if [ -n "$deb_url" ]; then
    local deb
    ensure_tmp_dir
    deb="${TMP_DIR}/${packages[0]}.deb"
    log "downloading ${packages[0]} .deb"
    fetch "$deb_url" "$deb"
    targets=("$deb")
  else
    [ -z "$key_url" ] || apt_ensure_repo "$key_url" "$keyring" "$sources" "$repo_line"
    # A package list that has never been refreshed makes the install fail
    # outright, so refresh when apt cannot currently see a candidate.
    if ! apt-cache policy "${targets[0]}" 2>/dev/null | grep -q 'Candidate: [0-9]'; then
      log "no candidate version visible; refreshing package lists (sudo)"
      sudo apt-get update -qq || die "apt-get update failed"
    fi
  fi

  log "installing via apt (sudo)"
  if [ "$FORCE" -eq 1 ]; then
    sudo apt-get install -y --reinstall "${targets[@]}" || die "apt-get install failed"
  else
    sudo apt-get install -y "${targets[@]}" || die "apt-get install failed"
  fi

  missing=()
  for p in "${packages[@]}"; do
    package_installed "$p" || missing+=("$p")
  done
  [ "${#missing[@]}" -eq 0 ] || die "still missing after the install: ${missing[*]}"

  if [ -n "$sources" ] && [ ! -r "$sources" ]; then
    warn "${packages[0]} installed but ${sources} is missing; apt upgrade will not track it"
  fi

  if [ "${#packages[@]}" -eq 1 ]; then
    log "${packages[0]} $(package_version "${packages[0]}") installed"
  else
    log "all ${#packages[@]} packages present"
  fi
  CHANGED=1
}

apt_ensure_repo() {
  local key_url="$1" keyring="$2" sources="$3" repo_line="$4" asc gpg_file
  [ -n "$keyring" ] && [ -n "$sources" ] && [ -n "$repo_line" ] ||
    die "apt_install: --key-url needs --keyring, --sources and --repo"

  if [ -r "$keyring" ]; then
    log "keyring ${keyring} already present"
  else
    log "installing keyring ${keyring} (sudo)"
    ensure_tmp_dir
    asc="${TMP_DIR}/${keyring##*/}.asc"
    gpg_file="${TMP_DIR}/${keyring##*/}"
    fetch "$key_url" "$asc"
    gpg --dearmor <"$asc" >"$gpg_file" || die "failed to dearmor ${key_url}"
    sudo install -m 0644 "$gpg_file" "$keyring" || die "failed to install ${keyring}"
  fi

  if [ "$(cat "$sources" 2>/dev/null)" = "$repo_line" ]; then
    log "${sources} already up to date"
  else
    log "writing ${sources} (sudo)"
    printf '%s\n' "$repo_line" | sudo tee "$sources" >/dev/null ||
      die "failed to write ${sources}"
  fi
}

# --- strategy: archive ----------------------------------------------------
# Download one or more archives, extract them, and place the result at --dest.
# Every archive is staged before --dest is touched, so a failed download cannot
# leave a half-installed mix of versions behind.
#
# With --pick, the matching files are installed into --dest as a shared
# directory (fonts). Without it, the archive's single top-level directory
# becomes --dest (themes), and its stamp disappears together with it.
archive_install() {
  local -a urls=() staged=()
  local name="" version="" dest="" pick="" stamp="" expect="" url file i=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)    need_value "$1" $#; name="$2"; shift 2 ;;
      --version) need_value "$1" $#; version="$2"; shift 2 ;;
      --url)     need_value "$1" $#; urls+=("$2"); shift 2 ;;
      --dest)    need_value "$1" $#; dest="$2"; shift 2 ;;
      --pick)    need_value "$1" $#; pick="$2"; shift 2 ;;
      --stamp)   need_value "$1" $#; stamp="$2"; shift 2 ;;
      --expect)  need_value "$1" $#; expect="$2"; shift 2 ;;
      *)         die "archive_install: unknown option: $1" ;;
    esac
  done
  [ -n "$name" ] && [ -n "$version" ] && [ -n "$dest" ] && [ "${#urls[@]}" -gt 0 ] ||
    die "archive_install: --name, --version, --dest and --url are required"

  if [ -z "$stamp" ]; then
    if [ -n "$pick" ]; then
      stamp="${dest}/.${name,,}-version"
    else
      stamp="${dest}/.installed-version"
    fi
  fi

  if [ "$FORCE" -eq 0 ] && stamp_matches "$stamp" "$version"; then
    log "${name} ${version} already installed, skipping"
    CHANGED=0
    return 0
  fi

  local work
  ensure_tmp_dir
  work="${TMP_DIR}/archive-${name}"
  rm -rf "$work"
  mkdir -p "${work}/staged"

  log "downloading ${name} ${version}"
  for url in "${urls[@]}"; do
    i=$((i + 1))
    file="${work}/${i}-${url##*/}"
    fetch "$url" "$file"
    archive_extract "$file" "${work}/staged"
  done

  if [ -n "$pick" ]; then
    mapfile -t staged < <(find "${work}/staged" -type f -name "$pick" | sort)
    [ "${#staged[@]}" -gt 0 ] || die "no ${pick} files found in the ${name} archives"
    mkdir -p "$dest"
    for file in "${staged[@]}"; do
      install -m 0644 "$file" "${dest}/${file##*/}"
    done
    log "installed ${#staged[@]} files into ${dest}"
  else
    mapfile -t staged < <(find "${work}/staged" -mindepth 1 -maxdepth 1)
    [ "${#staged[@]}" -eq 1 ] && [ -d "${staged[0]}" ] ||
      die "expected a single top-level directory in the ${name} archive"
    [ -z "$expect" ] || [ -f "${staged[0]}/${expect}" ] ||
      die "unexpected archive layout: ${expect} is missing from ${name}"
    mkdir -p "${dest%/*}"
    rm -rf "$dest"
    mv "${staged[0]}" "$dest"
    log "installed ${dest}"
  fi

  printf '%s\n' "$version" >"$stamp"
  rm -rf "$work"
  CHANGED=1
}

archive_extract() {
  local file="$1" dest="$2"
  case "$file" in
    *.tar.xz|*.txz) tar -xJf "$file" -C "$dest" ;;
    *.tar.gz|*.tgz) tar -xzf "$file" -C "$dest" ;;
    *.zip)          unzip -q -o "$file" -d "$dest" ;;
    *)              die "unsupported archive format: ${file##*/}" ;;
  esac || die "failed to extract ${file##*/}"
}

# --- strategy: git --------------------------------------------------------
# Track a project that publishes no releases as a shallow clone at --dest.
git_install() {
  local name="" repo="" branch="master" dest="" expect=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)   need_value "$1" $#; name="$2"; shift 2 ;;
      --repo)   need_value "$1" $#; repo="$2"; shift 2 ;;
      --branch) need_value "$1" $#; branch="$2"; shift 2 ;;
      --dest)   need_value "$1" $#; dest="$2"; shift 2 ;;
      --expect) need_value "$1" $#; expect="$2"; shift 2 ;;
      *)        die "git_install: unknown option: $1" ;;
    esac
  done
  [ -n "$name" ] && [ -n "$repo" ] && [ -n "$dest" ] ||
    die "git_install: --name, --repo and --dest are required"

  mkdir -p "${dest%/*}"
  [ "$FORCE" -eq 0 ] || rm -rf "$dest"

  if [ -d "${dest}/.git" ]; then
    log "updating ${name}"
    # Shallow repositories cannot merge, so refresh the tip and reset onto it.
    git -C "$dest" fetch --depth 1 origin "$branch" || die "failed to fetch ${repo}"
    git -C "$dest" reset --hard "origin/${branch}" >/dev/null || die "failed to update ${dest}"
  elif [ -e "$dest" ]; then
    die "${dest} exists but is not a clone of ${repo}; move it aside or use --force"
  else
    log "cloning ${name}"
    git clone --depth 1 --branch "$branch" "$repo" "$dest" || die "failed to clone ${repo}"
  fi

  [ -z "$expect" ] || [ -f "${dest}/${expect}" ] ||
    die "unexpected repository layout: ${dest}/${expect} is missing"
  log "installed ${dest}"
  CHANGED=1
}
