;; -*- coding: utf-8; lexical-binding: t; -*-

;;; Code:

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(let* ((minver "26.1"))
  (when (version< emacs-version minver)
    (error "Emacs v%s or higher is required" minver)))

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))

(defvar my-debug nil "Enable debug mode.")

(setq *is-a-mac* (eq system-type 'darwin))
(setq *win64* (eq system-type 'windows-nt))
(setq *cygwin* (eq system-type 'cygwin) )
(setq *linux* (or (eq system-type 'gnu/linux) (eq system-type 'linux)) )
(setq *unix* (or *linux* (eq system-type 'usg-unix-v) (eq system-type 'berkeley-unix)) )
(setq *emacs27* (>= emacs-major-version 27))

;; don't GC during startup to save time
(setq gc-cons-percentage 0.6)
(setq gc-cons-threshold most-positive-fixnum)

;; {{ emergency security fix
;; https://bugs.debian.org/766397
(with-eval-after-load 'enriched
  (defun enriched-decode-display-prop (start end &optional param)
    (list start end)))
;; }}

(setq *no-memory* (cond
                   (*is-a-mac*
                    ;; @see https://discussions.apple.com/thread/1753088
                    ;; "sysctl -n hw.physmem" does not work
                    (<= (string-to-number (shell-command-to-string "sysctl -n hw.memsize"))
                        (* 4 1024 1024)))
                   (*linux* nil)
                   (t nil)))

(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d")

(defconst my-site-lisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of lisp.")

(defun my-vc-merge-p ()
  "Use Emacs for git merge only?"
  (boundp 'startup-now))

(defun require-init (pkg &optional maybe-disabled)
  "Load PKG if MAYBE-DISABLED is nil or it's nil but start up in normal slowly."
  (when (or (not maybe-disabled) (not (my-vc-merge-p)))
    (load (file-truename (format "%s/%s" my-lisp-dir pkg)) t t)))

(defun my-add-subdirs-to-load-path (lisp-dir)
  "Add sub-directories under LISP-DIR into `load-path'."
  (let* ((default-directory lisp-dir))
    (setq load-path
          (append
           (delq nil
                 (mapcar (lambda (dir)
                           (unless (string-match-p "^\\." dir)
                             (expand-file-name dir)))
                         (directory-files my-site-lisp-dir)))
           load-path))))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))

  (require-init 'init-autoload)
  ;; `package-initialize' takes 35% of startup time
  ;; need check https://github.com/hlissner/doom-emacs/wiki/FAQ#how-is-dooms-startup-so-fast for solution
  (require-init 'init-modeline)
  (require-init 'init-utils)
  (require-init 'init-file-type)
  (require-init 'init-elpa)

  ;; for unit test
  (when my-disable-idle-timer
    (my-add-subdirs-to-load-path (file-name-as-directory my-site-lisp-dir)))

  ;; Any file use flyspell should be initialized after init-spelling.el
;;   (require-init 'init-spelling t)
  (require-init 'init-ibuffer t)
  (require-init 'init-ivy)
  (require-init 'init-windows)
  (require-init 'init-javascript t)
  (require-init 'init-org t)
  (require-init 'init-python t)
  (require-init 'init-lisp t)
  (require-init 'init-elisp t)
  (require-init 'init-yasnippet t)
  (require-init 'init-cc-mode t)
  (require-init 'init-linum-mode)
  (require-init 'init-git)
  (require-init 'init-gtags t)
  (require-init 'init-clipboard)
  (require-init 'init-ctags t)
  (require-init 'init-bbdb t)
  (require-init 'init-gnus t)
  (require-init 'init-lua-mode t)
  (require-init 'init-workgroups2 t) ; use native API in lightweight mode
  (require-init 'init-term-mode t)
  (require-init 'init-web-mode t)
  (require-init 'init-company t)
  (require-init 'init-chinese t) ;; cannot be idle-required
  ;; need statistics of keyfreq asap
  (require-init 'init-keyfreq t)
  (require-init 'init-httpd t)

  ;; projectile costs 7% startup time

  ;; don't play with color-theme in light weight mode
  ;; color themes are already installed in `init-elpa.el'
  (require-init 'init-theme)

  ;; misc has some crucial tools I need immediately
  (require-init 'init-essential)
  ;; handy tools though not must have
  (require-init 'init-misc t)

  (require-init 'init-emacs-w3m t)
  (require-init 'init-shackle t)
  (require-init 'init-dired t)
  (require-init 'init-writting t)
  (require-init 'init-hydra) ; hotkey is required everywhere
  ;; use evil mode (vi key binding)
;;  (require-init 'init-evil) ; init-evil dependent on init-clipboard

  ;; ediff configuration should be last so it can override
  ;; the key bindings in previous configuration
  (require-init 'init-ediff)

  ;; @see https://github.com/hlissner/doom-emacs/wiki/FAQ
  ;; Adding directories under "site-lisp/" to `load-path' slows
  ;; down all `require' statement. So we do this at the end of startup
  ;; NO ELPA package is dependent on "site-lisp/".
  (unless my-disable-idle-timer
    (my-add-subdirs-to-load-path (file-name-as-directory my-site-lisp-dir)))

  (require-init 'init-flymake t)

  (unless (my-vc-merge-p)
    ;; @see https://www.reddit.com/r/emacs/comments/4q4ixw/how_to_forbid_emacs_to_touch_configuration_files/
    ;; See `custom-file' for details.
    (setq custom-file (expand-file-name (concat my-emacs-d "custom-set-variables.el")))
    (if (file-exists-p custom-file) (load custom-file t t))

    ;; my personal setup, other major-mode specific setup need it.
    ;; It's dependent on *.el in `my-site-lisp-dir'
    (load (expand-file-name "~/.custom.el") t nil)))


;; @see https://www.reddit.com/r/emacs/comments/55ork0/is_emacs_251_noticeably_slower_than_245_on_windows/
;; Emacs 25 does gc too frequently
;; (setq garbage-collection-messages t) ; for debug
(defun my-cleanup-gc ()
  "Clean up gc."
  (setq gc-cons-threshold  67108864) ; 64M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'my-cleanup-gc)


;;; Local Variables:
;;; no-byte-compile: t
;;; End:
(put 'erase-buffer 'disabled nil)
(put 'dired-find-alternate-file 'disabled nil)

;; theme
(if (display-graphic-p) 
    (load-theme 'base16-zenburn t)
  nil)

;; recentf
(global-set-key "\C-x\C-r" 'counsel-recentf)

(global-set-key "\C-xg" 'magit-status)


(defun copy-line ()
  (interactive)
  (save-excursion
    (back-to-indentation)
    (kill-ring-save
     (point)
     (line-end-position)))
  (message "1 line copied"))


(global-set-key "\C-c\C-k" 'copy-line)


(defun connect-firett ()
  (interactive)
  (dired "/ssh:tt@192.168.1.124:/home/tt/"))

;; disable backup
(setq make-backup-files nil)

;; indent for bash scripts
(setq sh-basic-offset 2)

(setq gofmt-command "goimports")
;; (add-hook 'before-save-hook 'gofmt-before-save)


(add-hook 'go-mode-hook
          (lambda () (define-key go-mode-map (kbd "C-c C-f") #'gofmt)))

(global-set-key (kbd "C-.") 'counsel-etags-find-tag-at-point)
(global-set-key "\C-cg" 'counsel-git-grep)
(global-set-key "\C-cf" 'find-file-in-project)
(global-set-key "\M-/" 'comment-or-uncomment-region)
(global-set-key "\C-c\C-c" 'compile)

;;Custom Compile Command
(defun go-mode-setup ()
  (linum-mode 1)
;;  (go-eldoc-setup)
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save)
  (local-set-key (kbd "M-.") 'godef-jump)
  (setq compile-command "echo Building... && go build -v && echo Testing... && go test -v && echo Linter... && golint")
  (setq compilation-read-command nil)
  (define-key (current-local-map) "\C-c\C-c" 'compile))
;;  (local-set-key (kbd "M-,") 'compile)
(add-hook 'go-mode-hook 'go-mode-setup)

;;; I prefer cmd key for meta
;; (setq mac-option-key-is-meta nil
;;       mac-command-key-is-meta t
;;       mac-command-modifier 'meta
;;       mac-option-modifier 'none))

(require 'bash-completion)
(bash-completion-setup)

(rassq-delete-all 'modula-2-mode auto-mode-alist)

(load-theme 'moe-dark t)

;;(setq-default indent-tabs-mode t)
;;(setq-default tab-width 4) ; Assuming you want your tabs to be four spaces wide
;;(defvaralias 'c-basic-offset 'tab-width)


(require 'keyfreq)
(setq keyfreq-excluded-commands
      '(self-insert-command
        abort-recursive-edit
        forward-char
        backward-char
        previous-line
        next-line))
(keyfreq-mode 1)
(keyfreq-autosave-mode 1)
(set-frame-font "Cascadia Mono PL 12")

(setenv "PATH" (concat (getenv "PATH") ":$HOME/go/bin"))
(setq exec-path (append exec-path '("/home/tt/go/bin")))

(evil-mode t)

(global-undo-tree-mode)
(evil-set-undo-system 'undo-tree)

;;(custom-set-variables
;; '(gnutls-algorithm-priority "normal:-vers-tls1.3"))
