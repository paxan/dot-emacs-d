;;; init.el --- My emacs configuration file

;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen
(setq inhibit-startup-screen t)

;;;; package.el
(require 'package)
(setq package-user-dir "~/.emacs.d/elpa/")
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

;; Turn on the auto-revert mode, globally.
(global-auto-revert-mode t)

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
