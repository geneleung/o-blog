;;; o-blog.el --- 

;; Copyright © 2012 Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, 
;; Created: 2012-12-03
;; Last changed: 2013-03-25 16:23:17
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; 


;;; Code:
(eval-when-compile
  (require 'eieio)
  (require 'o-blog-utils)
  (require 'o-blog-tag)
  (require 'o-blog-entry)
  (require 'o-blog-i18n)
  (require 'o-blog-backend))

(defun o-blog-guess-backend-from-file (file)
  "Try to guess o-blog back from FILE or current buffer."
  (with-current-buffer (or (get-file-buffer file)
			   (find-file-noselect file))
    ;; Assume all mode end with "-mode"
    (intern (substring
	     (symbol-name major-mode) 0 -5))))

;;;###autoload
(defun o-blog-publish(&optional file backend)
  "Publish FILE using o-blog BACKEND.

If FILE is not provided, try to guess FILE and BACKEND from
current buffer."
  (interactive)
  (let* ((file
	  (or
	   file
	   (buffer-file-name)
	   (read-file-name "O-blog file to publish: " nil nil t)))
	 (default-directory (file-name-directory file))
	 (backend (or
		   backend
		   (o-blog-guess-backend-from-file file)))
	 (classfct (intern (format "ob:backend:%s" backend))))

    (let ((lib (intern (format "o-blog-backend-%s" backend))))
      (unless (featurep lib)
	(require lib)))

    (let* ((blog (funcall classfct file))
	   ;; Just an alias for backward compatibility
	   ;; TODO: Remove me
	   (BLOG blog))
      (ob:parse-config blog)
      (ob:parse-entries blog)
      (loop for type in '(articles pages snippets)
	    do (loop for entry in (slot-value blog type)
		     do (ob:convert-entry blog entry)))

      ;; (loop for type in '(articles pages)
      ;; 	  do (loop for entry in (slot-value blog type)
      ;; 		   do (ob:convert-entry blog entry)))
      
      ;;blog

      (ob:entry:publish (car (oref blog articles)))
      
(defun o-blog-publish-async-processes-sentinel (proc change)
  "Sentinel in charge of cleaning `org-publish-blog-async' on success."
  (when (eq (process-status proc) 'exit)
    (let ((status  (process-exit-status proc))
	  (cmd (process-get proc :cmd))
	  (cmd-buf (process-get proc :cmd-buf)))
      (if (not (eq 0 status))
	  (progn
	    (when (process-buffer proc)
	      (set-window-buffer (selected-window) cmd-buf))
	    (error "o-blog ERROR: %s" cmd))
	(message  "o-blog OK: %s" cmd))
      ;;(when cmd-buf (kill-buffer cmd-buf))
      )))

;;;###autoload
(defun o-blog-publish-async (file backend)
  "Publish FILE synchronously using BACKEND."
  (let* ((cmd-line (append command-line-args
			   `("--batch"
			     "-l" ,(concat (file-name-as-directory
					    user-emacs-directory)
					   "init.el")
			     ;;,@ob-async-opts
			     "--eval"
			     ,(format "(o-blog-publish \"%s\" '%s)"
				      file backend))))
	 (cmd-cli (mapconcat 'shell-quote-argument cmd-line " "))
	 (cmd-buf (get-buffer-create (format "o-blog build %s" file)))
	 (proc (progn
		 (with-current-buffer cmd-buf
		   (insert (format "Run: %s\n\n" cmd-cli)))
		 (apply 'start-process (car cmd-line)
			cmd-buf (car cmd-line) (cdr cmd-line)))))
    (set-window-buffer (selected-window) cmd-buf)
    (message "Run: %s" cmd-cli)
    (process-put proc :cmd (format "Build %s" file))
    (process-put proc :cmd-buf cmd-buf)
    (set-process-sentinel proc 'o-blog-publish-async-processes-sentinel)))




  
(defun ob:parse-blog-config (&optional file type)
  ""
  (interactive)
  
  (let* ((type (or (intern (format "ob:blog:%s" type)) 'ob:blog))
	 (file (or
		file
		(read-file-name "Blog configuration file: " nil nil t)))
	 (blog (funcall type file))
	 (lines (split-string
		 (with-temp-buffer
		   (insert-file-contents file)
		   (buffer-string))
		 "\n")))
    (save-match-data
      (loop for line in lines
	    when (string-match "^\\s-*\\([^#]+?\\)\\s-*=\\s-*\\(.+?\\)\\s-*$" line)
	    do (let ((k (intern (match-string 1 line)))
		     (v (match-string 2 line)))
		 (when (slot-exists-p blog k)
		   (set-slot-value blog k v)))))
    blog))





(provide 'o-blog)

;; o-blog.el ends here
