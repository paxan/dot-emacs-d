# .emacs.d

Personal Emacs config. Targets Emacs 30+, leans on built-ins, adds a small
set of third-party packages where the built-in story is still thin.

This README is the cheat sheet I want when I come back to Emacs after a few
months away. It documents what's wired up, the key bindings I actually use,
and how to relearn the fancy bits (completion, LSP, etc.).

## Prerequisites

Required:

- Emacs 30 or newer.
- `gpg` on PATH. `init.el` errors out early without it because GNU ELPA
  signatures cannot be verified otherwise. `brew install gnupg` on macOS.

Recommended:

- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads).
  Default frame font is `JetBrainsMono Nerd Font-16:weight=thin`.
- `ripgrep` for `consult-ripgrep` (`C-c r`). `brew install ripgrep`.
- `gopls` if you edit Go. `brew install gopls` or
  `go install golang.org/x/tools/gopls@latest`.
- `multimarkdown` for `markdown-mode` preview. `brew install multimarkdown`.

## Layout

```
init.el       single-file config, organized by ;;;; section headings
custom.el     auto-managed by Customize; kept separate from init.el
savefile/     persistent state: desktop, save-place, savehist
elpa/         installed packages (gitignored)
eln-cache/    native-compilation cache (gitignored)
```

To navigate `init.el`, use `M-g i` (`consult-imenu`): the `;;;;`
headings show up as a "Sections" group.

## What is wired up

### Completion stack (the big one)

The modern minibuffer trio plus `consult`:

| Package      | Role                                                          |
| ------------ | ------------------------------------------------------------- |
| `vertico`    | Vertical list UI for any `completing-read` call.              |
| `orderless`  | Match by space-separated fragments, any order, any position.  |
| `marginalia` | Right-aligned annotations (docstrings, file size, modes ...). |
| `consult`    | Power commands that feed into `completing-read`.              |

How it feels in practice. `C-x b` (`consult-buffer`) opens a vertical list
of buffers, recent files, and bookmarks. Type `init el` and orderless
matches both fragments anywhere in the candidate. `marginalia` shows the
buffer's major mode and file path next to each entry. `RET` selects;
`C-n` / `C-p` move; `M-.` previews. No need to type a prefix.

Bindings I use:

| Keys      | Command                    | What it does                          |
| --------- | -------------------------- | ------------------------------------- |
| `C-x b`   | `consult-buffer`           | Buffer/file/bookmark switcher.        |
| `C-c l`   | `consult-line`             | Fuzzy in-buffer line search.          |
| `M-y`     | `consult-yank-pop`         | Browse kill ring.                     |
| `M-g g`   | `consult-goto-line`        | Jump to line N.                       |
| `M-g i`   | `consult-imenu`            | Jump to function/section in buffer.   |
| `C-c r`   | `consult-ripgrep`          | Project-wide regex search via `rg`.   |
| `C-x C-f` | `find-file`                | File picker, now vertico-powered.     |
| `M-x`     | `execute-extended-command` | Command picker, vertico-powered.      |

Tip: inside any vertico prompt, `M-.` previews the candidate without
selecting it. `C-c C-c` (or `M-RET`, depending on context) accepts the
literal input instead of the highlighted candidate.

### Editing

- `paredit-mode` in `emacs-lisp-mode` and during `eval-expression`. Keeps
  parens balanced. `C-)` slurps the next sexp, `C-(` slurps the previous,
  `M-s` splices, `M-(` wraps.
- `rainbow-delimiters-mode` in all `prog-mode` buffers. Colours nested
  parens by depth.
- `company-mode` globally for in-buffer completion popups. `M-/` for
  `hippie-expand` (dabbrev plus filename plus lisp symbol completion).
- `completion-preview-mode` in `prog-mode`. Shows a greyed-out inline
  suggestion. `TAB` accepts.
- `delete-selection-mode`: type over a region to replace it.

### LSP

`eglot` for Go, via `gopls`. Diagnostics flow into `flymake`, hover
docs into `eldoc`, completion into `completion-at-point` (which
`company-capf` picks up).

`M-.` jumps to definition, `M-,` jumps back, `M-?` finds references,
`M-x eglot-rename` renames across the project, `C-h .` shows eldoc at point.

To add another language: install its language server, then add a hook like
`(add-hook 'python-mode-hook #'eglot-ensure)`.

### Session persistence

Three layers, all writing into `savefile/`:

- `desktop-save-mode`: which files are open, point/window/mode metadata,
  reopened on next launch. Dired buffers and large/log/archive files are
  excluded. TRAMP paths excluded.
- `save-place-mode`: point position remembered per file.
- `savehist-mode`: minibuffer history (commands, search rings, etc.)
  persisted across sessions.

`auto-save-visited-mode` is also on: real saves every 30 seconds for
visited files. If that is too eager, tune `auto-save-visited-interval`.

### Discoverability

- `which-key-mode`: after a prefix like `C-x`, a popup shows the
  next-key options.
- `repeat-mode`: chord-free repeat of common sequences. After `C-x o`,
  hit `o` to keep cycling windows.
- `marginalia` annotations make `M-x` self-documenting: hover any command
  with `C-n` and see its docstring summary.

### Visuals

- Theme: `tango-dark`. `solarized-theme` is installed but not loaded;
  `M-x load-theme RET solarized-dark` to try it.
- Font: JetBrainsMono Nerd Font, thin weight, 16pt. Adjust in
  `default-frame-alist` near the bottom of `init.el`.
- Ligatures via `ligature.el` in `prog-mode`. The font advertises which
  sequences to compose; the configured list is a superset covering Fira
  Code / JetBrainsMono / Cascadia.
- `pixel-scroll-precision-mode` for smooth GUI scrolling.
- `show-paren-mode` with `show-paren-context-when-offscreen`: if the
  matching paren is off-screen, it shows in the echo area.

### Other

- `magit` on `C-x g`.
- `ibuffer` replaces `buffer-menu` on `C-x C-b`.
- `M-RET` toggles fullscreen on macOS GUI frames.
- `s-=` / `s--` / `s-0` for text scale up / down / reset.
- `exec-path-from-shell` on macOS so GUI Emacs inherits shell PATH.
- `global-auto-revert-mode`: buffers reload when the file changes on disk.
- `use-short-answers`: `y`/`n` instead of `yes`/`no`.

## Getting (re)started

If it has been a while:

1. Open Emacs. Wait for `package-refresh-contents` and any installs.
2. Read this file. `C-x C-f ~/.emacs.d/README.md RET`.
3. Tour `init.el` by section: `C-x C-f ~/.emacs.d/init.el RET` then
   `M-g i` and pick a section.
4. Run `M-x consult-buffer`. Type a few characters. Notice the vertical
   list, the annotations, the fuzzy matching. That is the new normal.
5. `C-h k` (`describe-key`) then any keystroke shows what it is bound to.
   `C-h f` (`describe-function`) for any command name. `C-h v` for any
   variable. These three are the entire Emacs help system.
6. `M-x` and start typing. With orderless, you do not need prefixes:
   `buf list` finds `list-buffers`.

## Learning the fancy features

Modern Emacs rewards a few targeted reads:

- Built-in tutorial: `C-h t`. Still the best 30 minutes you can spend.
- Vertico/Orderless/Marginalia/Consult: see each package's README on
  GitHub. The Consult README in particular is a tour of useful commands
  worth skimming end to end.
- Eglot: `M-x eglot` to start it in a buffer, then `C-h v eglot-mode-map`
  to see the keymap.
- Magit: `C-x g`, then `?` shows transient menus for every operation.
- Paredit: `M-x paredit-cheatsheet` and the `paredit.el` commentary at the
  top of the source.

## Bumping the config

- Add a package: another `use-package` block under a `;;;;` section.
- Change a setting: `setopt` for customizable variables (so the type is
  checked), `setq` for plain ones. See `feedback_prefer_builtins` in my
  Claude memory for the modernization rules.
- After editing `init.el`: `M-x eval-buffer`, or restart Emacs.
- `custom.el` is auto-managed. Do not hand-edit. Things you set via
  `M-x customize` land there.

## Troubleshooting

- "gpg not found" on startup: install GnuPG, restart.
- Packages fail to install with signature errors: delete `elpa/gnupg/`
  and restart. The bootstrap in `init.el` re-imports the bundled keyring.
- Native compilation warnings pile up: silenced by default. Look in
  `*Native-compile-Log*` if curious.
- Desktop refuses to load: `rm savefile/.emacs.desktop.lock` if a stale
  lock survived a crash.
