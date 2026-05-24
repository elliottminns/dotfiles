;;; init.el --- Load the literate Emacs config -*- lexical-binding: t; -*-

(defconst dreams/config-dir
  (file-name-directory (or load-file-name buffer-file-name user-init-file)))

(defconst dreams/bootstrap-cache-dir
  (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache/")))

(unless (file-directory-p dreams/bootstrap-cache-dir)
  (make-directory dreams/bootstrap-cache-dir t))

(require 'org)

(let* ((org-file (expand-file-name "init.org" dreams/config-dir))
       (generated-file (expand-file-name "init.generated.el" dreams/bootstrap-cache-dir))
       (tangled-files (org-babel-tangle-file org-file generated-file "emacs-lisp")))
  (unless (member generated-file tangled-files)
    (error "Expected %s to be tangled from %s" generated-file org-file))
  (load generated-file nil 'nomessage))

;;; init.el ends here
