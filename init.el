;;; init.el --- My emacs configuration file

;;; Commentary:

;;; Code:

;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen
(setq inhibit-startup-screen t)

;; No menu
(menu-bar-mode -1)

;; Third-party packages (go-mode, posframe, paredit, ...) reference
;; functions from optional integrations we don't install (lsp-mode,
;; eglot) and use elisp idioms the modern compiler grumbles about
;; (defadvice, `case', etc.).  We can't fix any of it.  Quiet the
;; compilers and suppress the popup buffers; messages still accumulate
;; in *Native-compile-Log* / *Compile-Log* if we ever want to look.
(setq native-comp-async-report-warnings-errors 'silent)
(with-eval-after-load 'warnings
  (add-to-list 'warning-suppress-types '(native-compiler)))
(add-to-list 'display-buffer-alist
             '("\\*Compile-Log\\*"
               display-buffer-no-window
               (allow-no-window . t)))

;;;; Locations
(defvar dot-emacs-dir (file-name-directory load-file-name)
  "The root dir of the Emacs configuration.")
(defvar savefile-dir (expand-file-name "savefile" dot-emacs-dir)
  "This folder stores all the automatically generated save/history-files.")


;;;; package.el
(require 'package)
(setq package-user-dir (expand-file-name "elpa/" dot-emacs-dir))
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

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)

;; Keep GNU ELPA signing keys current as they rotate.  Once installed it
;; pulls fresh keys from the archive itself, so the bundled-Emacs keyring
;; above only has to be good enough to verify this one package.
(use-package gnu-elpa-keyring-update :ensure t)


;;;; macros
(defmacro after (mode &rest body)
  "`eval-after-load' MODE evaluate BODY."
  (declare (indent defun))
  `(eval-after-load ,mode
     '(progn ,@body)))


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
(setq require-final-newline t)

;; delete the selection with a keypress
(delete-selection-mode t)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; autosave the undo-tree history
(setq undo-tree-history-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq undo-tree-auto-save-history t)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; hippie expand is dabbrev expand on steroids
(setq hippie-expand-try-functions-list '(try-expand-dabbrev
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
(setq tab-always-indent 'complete)

;; enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)


;;;; global key bindings

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; enable fullscreen toggling via Alt-Enter
(when (and (eq system-type 'darwin) window-system)
  (global-set-key (kbd "M-RET") 'toggle-frame-fullscreen))


;;;; emacs lisp
(defun imenu-elisp-sections ()
  (setq imenu-prev-index-position-function nil)
  (add-to-list 'imenu-generic-expression '("Sections" "^;;;; \\(.+\\)$" 1) t))

(add-hook 'emacs-lisp-mode-hook 'imenu-elisp-sections)


;;;; Modern API for working with files and directories
(use-package f :ensure t)


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
  :init (setq markdown-command "multimarkdown"))


;;;; company
(use-package company
  :ensure t
  :config (progn
            ;; Use company-mode in all buffers
            (add-hook 'after-init-hook 'global-company-mode)))


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
(defun four-space-tabs-please! ()
  "Yes, 4 spaces in tabs!"
  (setq tab-width 4))

(use-package go-mode
  :ensure t
  :init   (add-hook 'go-mode-hook
                    (lambda ()
                      (four-space-tabs-please!)
                      (company-mode))))


;;;; mic-paren
(use-package mic-paren
  :ensure t
  :config (add-hook 'prog-mode-hook 'paren-activate))


;;;; smex (making M-x not suck!)
(use-package smex
  :ensure t
  :bind   (("M-x"         . smex)
           ("M-X"         . smex-major-mode-commands)
           ("C-c C-c M-x" . execute-extended-command))
  :config (setq smex-save-file (f-join savefile-dir "smex-items")))


;;;; ido
(use-package ido
  :config (setq ido-case-fold t
                ido-enable-prefix nil
                ido-create-new-buffer 'always
                ido-use-filename-at-point 'guess
                ido-max-prospects 10
                ido-save-directory-list-file (f-join savefile-dir "ido.last")
                ido-default-file-method 'selected-window
                ido-auto-merge-work-directories-length -1
                ido-ignore-buffers '("\\` ")))


;;;; smarter fuzzy matching for ido
(use-package flx-ido
  :ensure t
  :init   (flx-ido-mode +1)
  :config (progn
            ;; disable ido faces to see flx highlights
            (setq ido-use-faces nil)))


;;;; ido-completing-read+ (formerly ido-ubiquitous)
(use-package ido-completing-read+
  :ensure t
  :init   (progn
            (ido-mode 1)
            (ido-everywhere 1)
            (ido-ubiquitous-mode 1)))


;;;; flycheck
(use-package flycheck
  :ensure t
  :config (progn
            (setq flycheck-mode-line-lighter " fl")
            (add-hook 'after-init-hook 'global-flycheck-mode)))


;;;; git-grep
(when (require 'vc-git nil t)
  (defcustom git-grep-switches "--extended-regexp -I -n --no-color"
    "Switches to pass to `git grep'."
    :type 'string)

  (defun git-grep-get-shell-command (case-sensitive)
    (let ((root (vc-git-root default-directory)))
      (when (not root)
        (error "Directory %s is not part of a Git working tree" default-directory))
      (list (read-shell-command "Run git-grep (like this): "
                                (format "cd %s && git grep %s%s -e %s"
                                        root
                                        git-grep-switches
                                        (if case-sensitive "" " --ignore-case")
                                        (let ((thing (thing-at-point 'symbol)))
                                          (or (and thing (progn
                                                           (set-text-properties 0 (length thing) nil thing)
                                                           (shell-quote-argument thing)))
                                              "")))
                                'git-grep-history))))

  (defun git-grep (command-args)
    (interactive (git-grep-get-shell-command t))
    (let ((grep-use-null-device nil))
      (grep command-args)))

  (defun git-grep-i (command-args)
    (interactive (git-grep-get-shell-command nil))
    (let ((grep-use-null-device nil))
      (grep command-args))))


;;;; ensure we have solarized-theme
(use-package solarized-theme :ensure t :if window-system)


;;;; miscellaneous customizations

;; Theme and font settings
(when window-system
  (defun text-scale-default () (interactive) (text-scale-set 0))
  (bind-key "s-=" 'text-scale-increase)
  (bind-key "s--" 'text-scale-decrease)
  (bind-key "s-0" 'text-scale-default)
  (load-theme 'tango-dark t)

  (add-to-list 'default-frame-alist
               '(font . "JetBrainsMono Nerd Font Mono-15")))

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
(setq split-width-threshold 500)


(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;;; init.el ends here
