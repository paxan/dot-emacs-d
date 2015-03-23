;;; init.el --- My emacs configuration file

;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen
(setq inhibit-startup-screen t)

;;;; package.el
(require 'package)
(setq package-user-dir "~/.emacs.d/elpa/")
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

(defun mp-install-rad-packages ()
  "Install only the sweetest of packages."
  (interactive)
  (package-refresh-contents)
  (mapc #'(lambda (package)
            (unless (package-installed-p package)
              (package-install package)))
        '(cider
	  ido-ubiquitous
	  magit
	  paredit
	  projectile)))

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

;;;; paredit
(after "paredit-autoloads"

  ;; Enable `paredit-mode' in the minibuffer, during `eval-expression'.
  (defun conditionally-enable-paredit-mode ()
    (if (eq this-command 'eval-expression)
        (paredit-mode 1)))

  (add-hook 'minibuffer-setup-hook 'conditionally-enable-paredit-mode)

  (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
  (add-hook 'clojure-mode-hook 'paredit-mode))


;;;; magit
(global-set-key (kbd "C-x g") 'magit-status)


;;; init.el ends here
