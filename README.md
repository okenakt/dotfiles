# dotfiles

Oh my dotfiles.

## Usage

- `make help` to list available targets.
- `make list` to see discovered packages under `configs/`.
- `make dry-run` or `make dry-run pkg=<name>` to preview Stow changes.
- `make apply` or `make apply pkg=<name>` to apply all packages or one package.
- `make delete` or `make delete pkg=<name>` to remove symlinks for all packages or one package.
- `make backup` or `make backup pkg=<name>` to save existing target files before migration.
- `make restore backup=<dir>` or `make restore backup=<dir> pkg=<name>` to restore from a backup.

## Documents

- [Keybinding Principles](docs/keybinding-principles.md)
