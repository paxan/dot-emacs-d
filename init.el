;;; init.el --- My emacs configuration file

;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen
(setq inhibit-startup-screen t)


;;;; Locations
(defvar dot-emacs-dir (file-name-directory load-file-name)
  "The root dir of the Emacs configuration")
(defvar savefile-dir (expand-file-name "savefile" dot-emacs-dir)
  "This folder stores all the automatically generated save/history-files.")


;;;; package.el
(require 'package)
(setq package-user-dir (expand-file-name "elpa/" dot-emacs-dir))
(add-to-list 'package-archives '("melpa"        . "http://melpa.org/packages/")                t)
(add-to-list 'package-archives '("melpa-stable" . "http://melpa-stable.milkbox.net/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)


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
            (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
            (add-hook 'clojure-mode-hook 'paredit-mode)))


;;;; rainbow-delimiters
(use-package rainbow-delimiters
  :ensure t
  :config (add-hook 'prog-mode-hook 'rainbow-delimiters-mode-enable))


;;;; clojure-mode
(use-package clojure-mode :ensure t)


;;;; mic-paren
(use-package mic-paren
  :ensure t
  :config (add-hook 'prog-mode-hook 'paren-activate))


;;;; company
(use-package company
  :ensure t
  :config (progn
            ;; Use company-mode in all buffers
            (add-hook 'after-init-hook 'global-company-mode)))


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


;;;; ido-ubiquitous
(use-package ido-ubiquitous
  :ensure t
  :init   (progn
            (ido-mode +1)
            (ido-ubiquitous-mode +1)))


;;;; cider
(use-package cider
  :ensure t
  :bind   (("S-<return>" . cider-repl-newline-and-indent)
           ("C-c M-r"    . cider-refresh))
  :config (progn
            (unbind-key "C-j" cider-repl-mode-map)

            (setq cider-repl-history-file (f-join savefile-dir "cider-repl-history"))
            (setq cider-repl-use-clojure-font-lock t)
            (setq cider-repl-use-pretty-printing t)
            (setq cider-repl-popup-stacktraces t)
            (setq cider-auto-select-error-buffer nil)
            (setq nrepl-hide-special-buffers nil)
            (setq cider-repl-print-length 100)

            (add-hook 'cider-mode-hook 'cider-turn-on-eldoc-mode)
            (add-hook 'cider-repl-mode-hook 'subword-mode)))


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


;;;; default theme
(use-package solarized-theme
  :if     window-system
  :init   (load-theme 'solarized-dark t))


;;;; miscellaneous customizations

;; Theme and font settings
(when window-system
  (set-frame-font "Monaco-16" t))

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


;;; init.el ends here
