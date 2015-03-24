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
(use-package clojure-mode
  :ensure t)


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


;;;; ido-ubiquitous
(use-package ido-ubiquitous
  :ensure t
  :init (progn
          (ido-mode +1)
          (ido-ubiquitous-mode +1)))


;;;; miscellaneous customizations

;; Theme and font settings
(load-theme 'manoj-dark)
(when window-system
  (set-frame-font "Monaco-15" t))

;; This tells various "git" commands not to pipe their output through
;; "less" or similar.
(setenv "PAGER" "cat")

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
