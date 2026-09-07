# dotfiles

Oh my dotfiles.

## Usage

- `make install` to set up a new machine: install every dependency, then apply all packages. Needs sudo.
- `make help` to list available targets.
- `make list` to see discovered packages under `configs/`.
- `make dry-run` or `make dry-run pkg=<name>` to preview Stow changes.
- `make apply` or `make apply pkg=<name>` to back up conflicts, prepare targets, and apply all packages or one package.
- `make delete` or `make delete pkg=<name>` to remove symlinks for all packages or one package.
- `make backup` or `make backup pkg=<name>` to save existing target files before migration.
- `make prepare` or `make prepare pkg=<name>` to back up existing target files and remove Stow conflicts from the target before applying.
- `make restore backup=<dir>` or `make restore backup=<dir> pkg=<name>` to restore from a backup.
- `make gtk-theme` to install the Sweet GTK theme and candy-icons into `~/.themes` and `~/.icons`, as referenced by `configs/gtk-3.0`. Set `variant=<name>` for another Sweet variant or `force=1` to reinstall.
- `make fonts` to install the Pennywort font families, which supply the Nerd Font glyphs the i3 bar, tmux status line and rofi rely on. Set `force=1` to reinstall.
- `make packages` to install the Ubuntu-repository packages the configs depend on. `scripts/install.sh packages --list` shows the list and what is already present. Needs sudo.
- `make apt-apps` to install VS Code, Chrome and WezTerm from their apt repos, so `apt upgrade` keeps them current. Set `app=<name>` to limit to one. Needs sudo.

## Tree folding

Stow links a whole directory into this repo when the matching target directory
does not exist yet, so a package holding a single file can end up owning all of
`~/.config`. That is fine for apps that only read their config directory, but an
app that also writes runtime state there (VS Code: caches, logs, state DBs) then
writes it straight into the working tree. `NOFOLD_PKGS` in the Makefile lists the
packages that must keep a real target directory; `apply` and `dry-run` pass
`--no-folding` for those.

## Documents

- [Keybinding Principles](docs/keybinding-principles.md)
- [Git Account Setup](docs/git-account-setup.md)
