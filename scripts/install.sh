#!/usr/bin/env bash
# Install every external dependency the stowed configs need.
#
# Each subject below declares what to install by calling one of the strategies
# in lib/strategies.sh; the strategies own how the install is carried out.
set -euo pipefail

# shellcheck source=lib/strategies.sh
. "$(cd "${BASH_SOURCE[0]%/*}" && pwd)/lib/strategies.sh"

SUBJECTS=(packages apt-apps fonts gtk-theme)

# --- packages -------------------------------------------------------------
# Only packages available from Ubuntu's own repositories belong here. Each group
# names the config that pulls it in, so an entry can be traced back to the file
# that would break without it.
APT_PACKAGES=(
  # configs/i3: window manager, bar, lock screen, notifications, wallpaper,
  # launcher and compositor.
  i3-wm i3blocks i3lock dunst feh rofi picom

  # configs/alacritty, configs/tmux.
  alacritty tmux

  # configs/audio: audio-out needs pactl, speaker-test and whiptail;
  # configs/i3blocks/volume.sh prefers pamixer over the pactl fallback.
  pulseaudio-utils pipewire-bin alsa-utils pamixer whiptail

  # configs/i3blocks: temp.sh reads lm-sensors, net.sh reads iwgetid.
  lm-sensors wireless-tools

  # configs/i3 launches the NetworkManager tray applet.
  network-manager-gnome

  # configs/xsession: .xsessionrc calls setxkbmap.
  x11-xkb-utils

  # configs/xsession: remote sessions and the PipeWire sink .xsessionrc loads.
  # See docs/remote-audio.md.
  xrdp pipewire-module-xrdp

  # configs/bash: activates the powerline guard in .bashrc.
  powerline

  # The Makefile itself, plus the font cache the fonts subject refreshes.
  stow fontconfig
)

POWERLINE_BINDING="/usr/share/powerline/bindings/bash/powerline.sh"

subject_packages() {
  apt_install --packages "${APT_PACKAGES[*]}"

  # Report on powerline separately: apt can install it successfully while the
  # shell integration still fails to activate, and that is the part that
  # matters. configs/bash/.bashrc sources powerline only when both of these
  # exist, so verify against the same conditions the shell tests.
  package_installed powerline || return 0
  if command -v powerline-daemon >/dev/null 2>&1 && [ -r "$POWERLINE_BINDING" ]; then
    log "powerline: shell integration ready; start a new shell to pick up the prompt"
  else
    warn "powerline installed but ${POWERLINE_BINDING} or powerline-daemon is missing"
  fi
}

list_packages() {
  local p state
  for p in "${APT_PACKAGES[@]}"; do
    if package_installed "$p"; then
      state="$(package_version "$p")"
    else
      state="MISSING"
    fi
    printf '  %-26s %s\n' "$p" "$state"
  done
}

# --- apt-apps -------------------------------------------------------------
# All three are installed so that `apt upgrade` keeps them current afterwards.
# configs/vscode and configs/chrome stow wrapper scripts over these binaries,
# so `make apply` expects them to be present.
APT_APPS=(code chrome wezterm)
WEZTERM_KEYRING="/usr/share/keyrings/wezterm-fury.gpg"

subject_apt_apps() {
  local -a selected=("$@")
  local app
  [ "${#selected[@]}" -gt 0 ] || selected=("${APT_APPS[@]}")
  for app in "${selected[@]}"; do
    case "$app" in
      code)
        apt_install --package code \
          --deb-url "https://update.code.visualstudio.com/latest/linux-deb-x64/stable" \
          --sources "/etc/apt/sources.list.d/vscode.sources"
        ;;
      chrome)
        apt_install --package google-chrome-stable \
          --deb-url "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
          --sources "/etc/apt/sources.list.d/google-chrome.sources"
        ;;
      wezterm)
        apt_install --package wezterm \
          --key-url "https://apt.fury.io/wez/gpg.key" \
          --keyring "$WEZTERM_KEYRING" \
          --sources "/etc/apt/sources.list.d/wezterm.list" \
          --repo "deb [signed-by=${WEZTERM_KEYRING}] https://apt.fury.io/wez/ * *"
        ;;
      *)
        die "unknown app: ${app} (known: ${APT_APPS[*]})"
        ;;
    esac
  done
}

# --- fonts ----------------------------------------------------------------
# Pennywort is a Hack + BIZ UDGothic composite patched with Nerd Font glyphs.
# The i3 bar, tmux status line and rofi all depend on those glyphs: i3blocks
# emits Font Awesome arrows (U+F062/U+F063) and tmux embeds Powerline
# separators (U+E0B0), none of which exist in the default system fonts.
#
# Both families are installed because the configs reference Pennywort23 while
# Pennywort remains available for terminals that prefer the wider variant.
PENNYWORT_VERSION="v1.000"
PENNYWORT_FAMILIES=("Pennywort" "Pennywort23")
PENNYWORT_RELEASE_URL="https://github.com/okenakt/Pennywort/releases/download"
FONT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/fonts"

subject_fonts() {
  local -a urls=()
  local family
  for family in "${PENNYWORT_FAMILIES[@]}"; do
    urls+=(--url "${PENNYWORT_RELEASE_URL}/${PENNYWORT_VERSION}/${family}-${PENNYWORT_VERSION}.zip")
  done

  archive_install --name Pennywort --version "$PENNYWORT_VERSION" \
    "${urls[@]}" --dest "$FONT_DIR" --pick '*.ttf'
  [ "$CHANGED" -eq 1 ] || return 0

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || warn "fc-cache failed; run it manually"
  fi
  # Fontconfig resolves families once per process, so anything already running
  # keeps the fallback font it picked at startup. i3bar is the usual victim:
  # its glyphs stay as tofu until i3 is restarted with `i3-msg restart`.
  log "already-running programs keep their old font; restart them to pick this up"
  log "for the i3 bar specifically: i3-msg restart"
}

# --- gtk-theme ------------------------------------------------------------
# Sweet is pulled from a pinned release tarball; candy-icons publishes no
# releases, so it is tracked as a shallow clone. Both land under $HOME so that
# no root privileges are required.
SWEET_VERSION="v6.0"
SWEET_DEFAULT_VARIANT="Sweet-Ambar-Blue-Dark"
# The -v40 upstream variants target GNOME 40+ and are intentionally not offered.
SWEET_VARIANTS=(Sweet Sweet-Dark Sweet-Ambar Sweet-Ambar-Blue Sweet-Ambar-Blue-Dark Sweet-mars)
SWEET_RELEASE_URL="https://github.com/EliverLara/Sweet/releases/download"
CANDY_REPO="https://github.com/EliverLara/candy-icons.git"

variant="$SWEET_DEFAULT_VARIANT"

subject_gtk_theme() {
  local known found=0
  for known in "${SWEET_VARIANTS[@]}"; do
    [ "$variant" = "$known" ] && found=1
  done
  [ "$found" -eq 1 ] || die "unknown Sweet variant: ${variant} (known: ${SWEET_VARIANTS[*]})"

  archive_install --name "$variant" --version "$SWEET_VERSION" \
    --url "${SWEET_RELEASE_URL}/${SWEET_VERSION}/${variant}.tar.xz" \
    --dest "${HOME}/.themes/${variant}" --expect index.theme

  git_install --name candy-icons --repo "$CANDY_REPO" --branch master \
    --dest "${HOME}/.icons/candy-icons" --expect index.theme

  # Regenerate rather than update, so the cache can never lag behind a reset.
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${HOME}/.icons/candy-icons" >/dev/null 2>&1 ||
      warn "could not build the icon cache for candy-icons"
  fi
  log "settings.ini expects gtk-theme-name=${variant} and gtk-icon-theme-name=candy-icons"
}

# --- CLI ------------------------------------------------------------------
# Fail before touching anything when a subject cannot run to completion.
require_for() {
  case "$1" in
    packages)  require apt-get ;;
    apt-apps)  require apt-get; require curl; require gpg ;;
    fonts)     require curl; require unzip ;;
    gtk-theme) require curl; require tar; require git ;;
  esac
}

usage() {
  cat <<EOF
Usage: ${0##*/} [subject] [app...] [options]

Install the external dependencies the stowed configs need. With no subject,
every subject runs in order. The apt subjects require sudo.

Subjects:
  packages    The ${#APT_PACKAGES[@]} Ubuntu-repository packages the configs depend on
  apt-apps    code, chrome and wezterm, from their apt repos so apt upgrade
              keeps them current; name apps to limit which are handled
  fonts       The Pennywort font families (${PENNYWORT_VERSION})
  gtk-theme   The Sweet GTK theme (${SWEET_VERSION}) and the candy-icons icon theme

Options:
  -v, --variant <name>  Sweet variant to install (default: ${SWEET_DEFAULT_VARIANT})
  -f, --force           Reinstall even when already present or up to date
  -l, --list            Print the package list with its install state and exit
  -h, --help            Show this help

Sweet variants: ${SWEET_VARIANTS[*]}
EOF
}

main() {
  local -a subjects=() apps=()
  local subject

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)   FORCE=1; shift ;;
      -v|--variant) need_value "$1" $#; variant="$2"; shift 2 ;;
      -l|--list)    list_packages; exit 0 ;;
      -h|--help)    usage; exit 0 ;;
      -*)           usage >&2; die "unknown option: $1" ;;
      all)          subjects=("${SUBJECTS[@]}"); shift ;;
      packages|apt-apps|fonts|gtk-theme)
                    subjects+=("$1"); shift ;;
      *)            apps+=("$1"); shift ;;
    esac
  done

  [ "${#subjects[@]}" -gt 0 ] || subjects=("${SUBJECTS[@]}")
  if [ "${#apps[@]}" -gt 0 ] && [ "${subjects[*]}" != "apt-apps" ]; then
    usage >&2
    die "app names are only meaningful with the apt-apps subject"
  fi

  for subject in "${subjects[@]}"; do
    require_for "$subject"
  done

  for subject in "${subjects[@]}"; do
    LOG_TAG="$subject"
    case "$subject" in
      packages)  subject_packages ;;
      apt-apps)  subject_apt_apps "${apps[@]}" ;;
      fonts)     subject_fonts ;;
      gtk-theme) subject_gtk_theme ;;
    esac
  done

  LOG_TAG="install"
  log "done"
}

main "$@"
