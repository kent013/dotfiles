;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU-Emacs
;;; ---------
;;; load ~/.gnu-emacs or, if not exists /etc/skel/.gnu-emacs
;;; For a description and the settings see /etc/skel/.gnu-emacs
;;;	  ... for your private ~/.gnu-emacs your are on your one.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar init "~/.emacs.el")
(and (boundp 'init)
	 (stringp init)
	 (file-newer-than-file-p init "~/.emacs.elc")
	 (let ((mode-line-format "")
		   (mode-line-inverse-video nil))
	   (message	 "wait! Your %s needs recompiling..." init)
	   (sit-for 1)
	   (byte-compile-file init)
	   t)
	 (kill-emacs))

;; Custum Settings
;; ===============
;; To avoid any trouble with the customization system of GNU emacs
;; we set the default file ~/.gnu-emacs-custom
(setq custom-file "~/.gnu-emacs-custom")
(load "~/.gnu-emacs-custom" t t)
(if (eq window-system 'x)
	(progn
	  (define-key function-key-map [backspace] [8])
	  (put 'backspace 'ascii-character 8)
	  ))

;----------------------------------------------------------------------------
; misc
(setq auto-save-default nil)
(setq make-backup-files nil)

(iswitchb-mode 1)
(iswitchb-default-keybindings)
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

(setq kill-whole-line t)
(setq require-final-newline t)
(setq next-line-add-newlines nil)

(require 'physical-line)
(setq-default physical-line-mode t)
(setq inhibit-startup-message t)
(setq initial-scratch-message "")
(require 'ido)
(ido-mode t)

;----------------------------------------------------------------------------
; php
(load-library "php-mode")
(require 'php-mode)
(require 'redo)
(fset 'yes-or-no-p 'y-or-n-p)

(add-hook 'php-mode-user-hook
          '(lambda ()
             (setq tab-width 4)
             (setq c-basic-offset 4)
             (setq indent-tabs-mode nil)))

;----------------------------------------------------------------------------
; ruby
(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files" t)
(setq auto-mode-alist
	  (append '(("\\.rb$" . ruby-mode)) auto-mode-alist))
(setq interpreter-mode-alist (append '(("ruby" . ruby-mode))
									 interpreter-mode-alist))
(autoload 'run-ruby "inf-ruby"
  "Run an inferior Ruby process")
(autoload 'inf-ruby-keys "inf-ruby"
  "Set local key defs for inf-ruby in ruby-mode")
(add-hook 'ruby-mode-hook
		  '(lambda ()
			 (inf-ruby-keys)))

;----------------------------------------------------------------------------
;perl
(autoload 'cperl-mode "cperl-mode"
  "alternate mode for editing Perl programs" t)
(add-to-list 'auto-mode-alist
  '("\\.\\([pP][Llm]\\|al\\|t\\|cgi\\)\\'" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("perl" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("perl5" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("miniperl" . cperl-mode))
(defalias 'perl-mode 'cperl-mode)
 
(setq cperl-indent-level 2
      cperl-continued-statement-offset 2
      cperl-close-paren-offset -2
      cperl-label-offset -2
      cperl-comment-column 40
      cperl-highlight-variables-indiscriminately t
      cperl-indent-parens-as-block t
	  cperl-indent-region-fix-constructs 1
	  cperl-indent-subs-specially nil
	  cperl-tab-always-indent t
      cperl-font-lock t)
(require 'flymake)
(require 'set-perl5lib)

(set-face-background 'flymake-errline "red4")
(set-face-foreground 'flymake-errline "black")
(set-face-background 'flymake-warnline "yellow")
(set-face-foreground 'flymake-warnline "black")

(defun flymake-display-err-minibuf ()
  "Displays the error/warning for the current line in the minibuffer"
  (interactive)
  (let* ((line-no             (flymake-current-line-no))
         (line-err-info-list  (nth 0 (flymake-find-err-info
                                      flymake-err-info line-no)))
         (count               (length line-err-info-list)))
    (while (> count 0)
      (when line-err-info-list
        (let* ((file       (flymake-ler-file (nth (1- count)
	                                          line-err-info-list)))
			   (full-file  (flymake-ler-full-file (nth (1- count)
											  line-err-info-list)))
		       (text       (flymake-ler-text (nth (1- count)
											  line-err-info-list)))
			   (line       (flymake-ler-line (nth (1- count)
											  line-err-info-list))))
          (message "[%s] %s" line text)))
      (setq count (1- count)))))

(defvar flymake-perl-err-line-patterns
  '(("\\(.*\\) at \\([^ \n]+\\) line \\([0-9]+\\)[,.\n]" 2 3 nil 1)))

(defconst flymake-allowed-perl-file-name-masks
  '(("\\.pl$" flymake-perl-init)
    ("\\.pm$" flymake-perl-init)
    ("\\.t$" flymake-perl-init)))

(defun flymake-perl-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
                     'flymake-create-temp-inplace))
         (local-file (file-relative-name
                      temp-file
                      (file-name-directory buffer-file-name))))
    (list "perl" (list "-wc" local-file))))

(defun flymake-perl-load ()
  (interactive)
  (defadvice flymake-post-syntax-check
    (before flymake-force-check-was-interrupted)
  (setq flymake-check-was-interrupted t))
  (ad-activate 'flymake-post-syntax-check)
  (setq flymake-allowed-file-name-masks
    (append flymake-allowed-file-name-masks
            flymake-allowed-perl-file-name-masks))
  (setq flymake-err-line-patterns flymake-perl-err-line-patterns)
  (set-perl5lib)
  (flymake-mode t)
  (setq indent-tabs-mode nil)
  (setq tab-width nil)
  (require 'auto-complete)
  (require 'perl-completion)
  (add-to-list 'ac-sources 'ac-source-perl-completion)
  (perl-completion-mode t)
)

(add-hook 'cperl-mode-hook 'flymake-perl-load)

;----------------------------------------------------------------------------
; js2
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
(add-hook 'js2-mode-hook
  #'(lambda ()
    (require 'js)
    (setq js-indent-level 2
          js-expr-indent-offset 2
          indent-tabs-mode nil)
    (set (make-local-variable 'indent-line-function) 'js-indent-line)))
;----------------------------------------------------------------------------
; jaspace
;(require 'jaspace)
;(global-font-lock-mode t)
;(jaspace-mode-on)
;(setq jaspace-highlight-tabs t)
;(setq jaspace-highlight-tabs ?^)

;----------------------------------------------------------------------------
; abbrev
(quietly-read-abbrev-file)
(setq save-abbrevs t)
(setq abbrev-file-name "~/.abbrev_defs")

;----------------------------------------------------------------------------
; tab
(setq default-tab-width 4)
(setq c-basic-offset  4)

;----------------------------------------------------------------------------
; key settings
(global-set-key [f10] 'mark-whole-buffer)
(global-set-key [f11] 'redo)
(global-set-key [f20] 'indent-region)
(global-set-key [f12] 'undo)
(global-set-key "\C-@" 'dabbrev-expand)
(global-set-key "\M-@" 'set-mark-command)
(global-set-key "\M-G" 'goto-line)
(global-set-key "\C-m" 'reindent-then-newline-and-indent)
(global-set-key "\C-x\C-b" 'buffer-menu)

;----------------------------------------------------------------------------
; appearance settings
(require 'color-theme)
(color-theme-initialize)
(color-theme-billw)
(setq frame-title-format "%b")
(setq line-number-mode t)
(setq column-number-mode t)
(setq transient-mark-mode t)
(display-time)
(setq blink-matching-paren t)					; default is t
(setq blink-matching-delay 1)					; default is 1
(setq blink-matching-paren-distance 12000 )		; default is 12000
(setq show-paren-mode t)

;----------------------------------------------------------------------------
; session settings
(when (require 'session nil t)
  (setq session-initialize '(de-saveplace session keys menus)
        session-globals-include '((kill-ring 50)
                                  (session-file-alist 100 t)
                                  (file-name-history 100)))
  (add-hook 'after-init-hook 'session-initialize))

;----------------------------------------------------------------------------
; desktop settings
(desktop-save-mode 1)

;;;
