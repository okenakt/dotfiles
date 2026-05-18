# Keybinding Principles

Shared keybinding rules for this repository.

## Modifier Keys

Some modifier keys have base roles that should stay stable across applications.

### Base Roles

- `Super`: `OS Context Control`
  Changes the active OS-level context across windows, workspaces, and applications.
- `Alt`: `Application Context Control`
  Changes the active in-app context such as pane, tab, group, or surface.
- `Ctrl`: `Action Shortcut`
  Performs an action in the current context. The current context may be a pane, editor, terminal, tab, or the application itself.
- `Shift`: `Variant Modifier`
  Changes the base operation into a variant such as move, select, extend, or reverse action.

### Composition Rule

Combined modifiers are read by composition.

- `Ctrl + Alt`: `Action Shortcut on Application Context`
- `Ctrl + Shift`: `Variant of Action Shortcut`
- `Alt + Shift`: `Variant of Application Context Control`
- `Super + Shift`: `Variant of OS Context Control`
- `Super + Ctrl`: `OS-Level Action Shortcut`

`Super + Alt` is avoided because it mixes OS scope and application scope.

## Semantic Keys

Some keys carry reserved meanings regardless of modifier scope.

- `Enter`: `Command Entry`
  Opens a command or launcher entry point in the current scope.
- `` ` ``: `Terminal Surface`
  Opens, focuses, or prefixes terminal-related operations in the current scope.

Examples:

- `Super + Enter`: OS command entry
- `Super + \``: OS terminal launch
- `Alt + Enter`: application command entry
- `Alt + \``: application terminal surface
- `Ctrl + \``: action on terminal surface in the current application context
- `Ctrl + Alt + \``: open a new terminal in the current application context
