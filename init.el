;;; init.el --- My emacs configuration file  -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; Turn off mouse interface early in startup to avoid momentary display
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; No splash screen
(setopt inhibit-startup-screen t)

;; No menu
(menu-bar-mode -1)

;; Third-party packages (go-mode, posframe, paredit, ...) reference
;; functions from optional integrations we don't install (lsp-mode,
;; eglot) and use elisp idioms the modern compiler grumbles about
;; (defadvice, `case', etc.).  We can't fix any of it.  Quiet the
;; compilers and suppress the popup buffers; messages still accumulate
;; in *Native-compile-Log* / *Compile-Log* if we ever want to look.
(setopt native-comp-async-report-warnings-errors 'silent)
(with-eval-after-load 'warnings
  (add-to-list 'warning-suppress-types '(native-compiler)))
(add-to-list 'display-buffer-alist
             '("\\*Compile-Log\\*"
               display-buffer-no-window
               (allow-no-window . t)))

;;;; Locations
(defvar savefile-dir (expand-file-name "savefile" user-emacs-directory)
  "This folder stores all the automatically generated save/history-files.")


;;;; package.el
(require 'package)
(setopt package-user-dir (expand-file-name "elpa/" user-emacs-directory))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

;; Emacs.app launched from Finder/Dock inherits only a minimal system
;; PATH, so Homebrew binaries (gpg, etc.) are invisible.  Prepend the
;; usual bin dirs early so the gpg check below works before
;; `exec-path-from-shell' runs.
(when (eq system-type 'darwin)
  (dolist (dir '("/opt/homebrew/bin" "/usr/local/bin"))
    (when (file-directory-p dir)
      (add-to-list 'exec-path dir)
      (setenv "PATH" (concat dir ":" (or (getenv "PATH") ""))))))

;; package.el shells out to gpg for signature verification.  Without it,
;; both the keyring bootstrap below and every signed package install
;; later will fail in confusing ways.  Halt early with a clear message.
(unless (executable-find "gpg")
  (error
   (concat
    "gpg not found on PATH.  GNU ELPA package signatures cannot be verified.\n"
    "Install GnuPG and restart Emacs:\n"
    "  macOS:         brew install gnupg\n"
    "  Debian/Ubuntu: sudo apt install gnupg\n"
    "  Fedora/RHEL:   sudo dnf install gnupg2\n"
    "  Arch:          sudo pacman -S gnupg")))

;; On a pristine checkout the ELPA gnupg/ keyring is empty, so signature
;; verification of GNU ELPA packages fails.  Import the keyring that ships
;; with Emacs before the first package fetch.
(let ((keyring-dir (expand-file-name "gnupg" package-user-dir))
      (bundled    (expand-file-name "package-keyring.gpg" data-directory)))
  (when (and (not (file-directory-p keyring-dir))
             (file-exists-p bundled))
    (package-import-keyring bundled)))

(package-initialize)

;; Keep GNU ELPA signing keys current as they rotate.  Once installed it
;; pulls fresh keys from the archive itself, so the bundled-Emacs keyring
;; above only has to be good enough to verify this one package.
(use-package gnu-elpa-keyring-update :ensure t)


;;;; editor settings from Prelude

;; Death to the tabs!  However, tabs historically indent to the next
;; 8-character offset; specifying anything else will cause *mass*
;; confusion, as it will change the appearance of every existing file.
;; In some cases (python), even worse -- it will change the semantics
;; (meaning) of the program.
;;
;; Emacs modes typically provide a standard means to change the
;; indentation width -- eg. c-basic-offset: use that to adjust your
;; personal indentation width, while maintaining the style (and
;; meaning) of any files you load.
(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
(setq-default tab-width 8)            ;; but maintain correct appearance

;; Newline at end of file
(setopt require-final-newline t)

;; delete the selection with a keypress
(delete-selection-mode t)

;; store all backup and autosave files in the tmp dir
(setopt backup-directory-alist
        `((".*" . ,temporary-file-directory)))
(setopt auto-save-file-name-transforms
        `((".*" ,temporary-file-directory t)))

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; hippie expand is dabbrev expand on steroids
(setopt hippie-expand-try-functions-list '(try-expand-dabbrev
                                           try-expand-dabbrev-all-buffers
                                           try-expand-dabbrev-from-kill
                                           try-complete-file-name-partially
                                           try-complete-file-name
                                           try-expand-all-abbrevs
                                           try-expand-list
                                           try-expand-line
                                           try-complete-lisp-symbol-partially
                                           try-complete-lisp-symbol))

;; smart tab behavior - indent or complete
(setopt tab-always-indent 'complete)

;; y/n in place of yes/no everywhere (Emacs 28+).
(setopt use-short-answers t)

;; Show matching paren; if the partner is offscreen, show it in the
;; echo area (Emacs 29+).  Replaces the old `mic-paren' package.
(setopt show-paren-context-when-offscreen t)
(show-paren-mode 1)


;;;; session persistence: desktop + save-place + savehist
;;
;; `desktop' records which files are open, plus point/window/mode
;; metadata, and reopens them on next launch.  `save-place' remembers
;; point per file.  `savehist' persists minibuffer history.  None of
;; these store unsaved buffer contents -- normal save-on-exit prompts
;; still apply, and `auto-save-mode' handles crash recovery.
(use-package desktop
  :init
  (setopt desktop-path             (list savefile-dir)
          desktop-dirname          savefile-dir
          desktop-save             t       ; save silently on exit
          desktop-load-locked-desktop t    ; allow GUI + terminal Emacs to coexist
          desktop-restore-eager    5       ; restore a few; lazy-load the rest
          desktop-restore-frames   nil     ; skip frame layout (mixed GUI/tty)
          desktop-files-not-to-save
          (rx (or
               ;; TRAMP/remote files and ange-ftp (Emacs defaults)
               (seq bos "/" (1+ (not (any "/:"))) ":")
               (seq "(ftp)" eos)
               ;; large/log/archive files
               (seq "." (or "log" "gz" "bz2" "xz" "zip") eos))))
  :config
  (add-to-list 'desktop-modes-not-to-save 'dired-mode)
  (desktop-save-mode 1))

(use-package saveplace
  :init   (setopt save-place-file (file-name-concat savefile-dir "saveplace"))
  :config (save-place-mode 1))

(use-package savehist
  :init   (setopt savehist-file (file-name-concat savefile-dir "savehist")
                  history-length 1000
                  savehist-save-minibuffer-history t
                  savehist-additional-variables '(search-ring regexp-search-ring))
  :config (savehist-mode 1))


;;;; global key bindings

;; replace buffer-menu with ibuffer
(keymap-global-set "C-x C-b" #'ibuffer)

;; enable fullscreen toggling via Alt-Enter
(when (and (eq system-type 'darwin) (display-graphic-p))
  (keymap-global-set "M-RET" #'toggle-frame-fullscreen))


;;;; emacs lisp

;; `elisp-flymake-byte-compile' spawns a clean sub-Emacs that knows
;; nothing about installed packages, so symbols like `paredit-mode' or
;; `vertico-mode' look undefined.  Hand it our `load-path' so it can
;; resolve them.
(setopt elisp-flymake-byte-compile-load-path (cons "./" load-path))

(defun imenu-elisp-sections ()
  "Add an Imenu \"Sections\" group keyed on `;;;;' headings."
  (setq imenu-prev-index-position-function nil)
  (add-to-list 'imenu-generic-expression '("Sections" "^;;;; \\(.+\\)$" 1) t))

(add-hook 'emacs-lisp-mode-hook 'imenu-elisp-sections)

;; Auto-insert a lexical-binding cookie when creating a brand-new .el
;; file. Without it Emacs falls back to dynamic scoping and warns on
;; load. Guarded so it fires only for new files we're about to write,
;; never for existing files we're just visiting.
(defun pr/elisp-insert-lexical-binding-cookie ()
  "Insert a `lexical-binding' cookie when visiting a new Elisp file."
  (when (and buffer-file-name
             (string-suffix-p ".el" buffer-file-name)
             (not (file-exists-p buffer-file-name))
             (zerop (buffer-size)))
    (insert ";;; -*- lexical-binding: t; -*-\n\n")))

(add-hook 'emacs-lisp-mode-hook #'pr/elisp-insert-lexical-binding-cookie)

;; Built-in flymake picks up `elisp-flymake-byte-compile' and
;; `elisp-flymake-checkdoc' automatically.
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

;; Prepend the lexical-binding cookie to `initial-scratch-message'.
(setq initial-scratch-message
      (concat ";;; -*- lexical-binding: t -*-\n\n" initial-scratch-message))


;;;; get $PATH from the shell
(use-package exec-path-from-shell
  :ensure t
  :if     (eq system-type 'darwin)
  :init   (exec-path-from-shell-initialize))


;;;; magit
(use-package magit
  :ensure t
  :bind   ("C-x g" . magit-status))


;;;; paredit
(use-package paredit
  :ensure t
  :config (progn
            ;; Enable `paredit-mode' in the minibuffer, during `eval-expression'.
            (defun conditionally-enable-paredit-mode ()
              (if (eq this-command 'eval-expression)
                  (paredit-mode 1)))
            (add-hook 'minibuffer-setup-hook 'conditionally-enable-paredit-mode)
            (add-hook 'emacs-lisp-mode-hook 'paredit-mode)))


;;;; rainbow-delimiters
(use-package rainbow-delimiters
  :ensure t
  :config (add-hook 'prog-mode-hook 'rainbow-delimiters-mode-enable))


;;;; markdown-mode
(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("\\.md\\'" . gfm-mode))
  :init (setopt markdown-command "multimarkdown"))


;;;; company
(use-package company
  :ensure t
  :config (add-hook 'after-init-hook 'global-company-mode))


;;;; eglot — LSP client built into Emacs 29+.  Drives diagnostics via
;;;; flymake, hover docs via eldoc, completion via completion-at-point
;;;; (picked up automatically by `company-capf').
;;;;
;;;; For Go you need `gopls' on PATH:
;;;;   brew install gopls
;;;; or
;;;;   go install golang.org/x/tools/gopls@latest
(use-package eglot
  :hook (go-mode . eglot-ensure))


;;;; go-mode
(defun pr/go-mode-setup ()
  "Per-buffer setup for `go-mode'."
  (setq tab-width 4)
  (company-mode))

(use-package go-mode
  :ensure t
  :hook   (go-mode . pr/go-mode-setup))


;;;; vertico — vertical completion UI (Emacs `completing-read').
(use-package vertico
  :ensure t
  :init   (vertico-mode 1)
  :custom (vertico-cycle t))


;;;; orderless — flexible, space-separated matching.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))


;;;; marginalia — rich annotations in the minibuffer.
(use-package marginalia
  :ensure t
  :init (marginalia-mode 1))


;;;; consult — power commands over completing-read.  `consult-ripgrep'
;;;; needs `rg' on PATH (brew install ripgrep); the built-in
;;;; `project-find-regexp' (C-x p g) covers the ripgrep-less case.
(use-package consult
  :ensure t
  :bind (("C-x b"   . consult-buffer)
         ("C-c l"   . consult-line)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("C-c r"   . consult-ripgrep)))


;;;; ensure we have solarized-theme
(use-package solarized-theme :ensure t :if (display-graphic-p))


;;;; miscellaneous customizations

;; Theme and font settings
(when (display-graphic-p)
  (defun text-scale-default () (interactive) (text-scale-set 0))
  (bind-key "s-=" 'text-scale-increase)
  (bind-key "s--" 'text-scale-decrease)
  (bind-key "s-0" 'text-scale-default)
  (load-theme 'tango-dark t)

  (add-to-list 'default-frame-alist
               '(font . "JetBrainsMono Nerd Font-16:weight=thin")))

;; ligature.el discovers what the active font's OpenType tables
;; advertise and composes those character sequences automatically.  The
;; superset list below covers Fira Code, JetBrainsMono, Cascadia Code,
;; etc.; the font picks which ones actually render.  Programming modes
;; only, so markdown/text source stays unmolested.
(use-package ligature
  :ensure t
  :config
  (ligature-set-ligatures
   'prog-mode
   '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
     ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
     "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
     "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
     "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
     "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
     "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
     "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
     ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
     "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
     "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
     "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "(*" "*)" "\\\\"
     "://"))
  (global-ligature-mode t))

;; This tells various "git" commands not to pipe their output through
;; "less" or similar.
(setenv "GIT_PAGER" "cat")

;; At work I sometimes use a frame that's 166 characters wide.  When I
;; do that, I find that many windows split horizontally -- for
;; example, if I have a single window, displaying a buffer of source
;; code, typing C-x v d will split that window so that the new vc-dir
;; window is to the right.  I hate that.  I want that new window to be
;; below my source, not next to it.
;;
;; So this makes that not happen.
(setopt split-width-threshold 500)


;;;; Emacs 30 niceties — additive quality-of-life

;; Smooth pixel scrolling in GUI Emacs (Emacs 29+).
(when (display-graphic-p)
  (pixel-scroll-precision-mode 1))

;; Chord-free repeat of common command sequences (Emacs 28+).
(repeat-mode 1)

;; Built-in in Emacs 30: show key hints after a prefix.
(which-key-mode 1)

;; Stop dired buffers from piling up (Emacs 28+).
(setopt dired-kill-when-opening-new-dired-buffer t)

;; Inline grey "ghost" completion previews in prog buffers (Emacs 30).
(add-hook 'prog-mode-hook #'completion-preview-mode)

;; Save visited buffers to disk on a timer (Emacs 26+).  These are real
;; saves, not `#file#' auto-saves.
(setopt auto-save-visited-interval 30)
(auto-save-visited-mode 1)


(setopt custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;;; init.el ends here
