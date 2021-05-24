;;; elfeed-autotag.el --- easy auto-tagging for elfeed -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Paul Elms
;; Derived from elfeed-org by Remy Honig
;;
;; Author: Paul Elms <https://paul.elms.pro>
;; Maintainer: Paul Elms <paul@elms.pro>
;; Version: 0.0.1
;; Keywords: news
;; Homepage: https://github.com/paulelms/elfeed-autotag
;; Package-Requires: ((emacs "28.0.50") (elfeed "3.4.1") (org "8.2.7") (dash "2.10.0") (s "1.9.0") (cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;  Easy auto-tagging for elfeed-protocol (and elfeed in general).
;;  Thanks to elfeed-org by Remy Honig for starting point.
;;
;;; Code:

(require 'elfeed)
(require 'org)
(require 'dash)
(require 's)
(require 'cl-lib)

(defgroup elfeed-autotag nil
  "Configure the Elfeed RSS reader with an Orgmode file"
  :group 'comm)

(defcustom pvv-elfeed-autotag-tree-id "elfeed"
  "The tag or ID property on the trees containing the RSS feeds."
  :group 'elfeed-autotag
  :type 'string)

(defcustom pvv-elfeed-autotag-ignore-tag "ignore"
  "The tag on the feed trees that will be ignored."
  :group 'elfeed-autotag
  :type 'string)

(defcustom pvv-elfeed-autotag-files (list (locate-user-emacs-file "elfeed.org"))
  "The files where we look to find trees with the `pvv-elfeed-autotag-tree-id'."
  :group 'elfeed-autotag
  :type '(repeat (file :tag "org-mode file")))

(defvar elfeed-autotag-new-entry-hook nil
  "List of new-entry tagger hooks created by elfeed-autotag.")

(defun pvv-elfeed-autotag-check-configuration-file (file)
  "Make sure FILE exists."
  (when (not (file-exists-p file))
    (error "Elfeed-autotag cannot open %s.  Make sure it exists or customize the variable \'pvv-elfeed-autotag-files\'"
           (abbreviate-file-name file))))

(defun pvv-elfeed-autotag-is-headline-contained-in-elfeed-tree ()
  "Is any ancestor a headline with the elfeed tree id.
Return t if it does or nil if it does not."
  (let ((result nil))
    (save-excursion
      (while (and (not result) (org-up-heading-safe))
        (setq result (member pvv-elfeed-autotag-tree-id (org-get-tags))))
    result)))


(defun pvv-elfeed-autotag-import-trees (tree-id)
  "Get trees with \":ID:\" property or tag of value TREE-ID.
Return trees with TREE-ID as the value of the id property or
with a tag of the same value.  Setting an \":ID:\" property is not
recommended but I support it for backward compatibility of
current users."
  (org-element-map
      (org-element-parse-buffer)
      'headline
    (lambda (h)
      (when (or (member tree-id (org-element-property :tags h))
                (equal tree-id (org-element-property :ID h))) h))))


(defun pvv-elfeed-autotag-convert-tree-to-headlines (parsed-org)
  "Get the inherited tags from PARSED-ORG structure if MATCH-FUNC is t.
The algorithm to gather inherited tags depends on the tree being
visited depth first by `org-element-map'.  The reason I don't use
`org-get-tags-at' for this is that I can reuse the parsed org
structure and I am not dependent on the setting of
`org-use-tag-inheritance' or an org buffer being present at
all.  Which in my opinion makes the process more traceable."
  (let* ((tags '())
         (level 1))
    (org-element-map parsed-org 'headline
      (lambda (h)
        (let* ((current-level (org-element-property :level h))
               (delta-level (- current-level level))
               (delta-tags (--map (intern (substring-no-properties it))
                                  (org-element-property :tags h)))
               (heading (org-element-property :raw-value h)))
          ;; update the tags stack when we visit a parent or sibling
          (unless (> delta-level 0)
            (let ((drop-num (+ 1 (- delta-level))))
              (setq tags (-drop drop-num tags))))
          ;; save current level to compare with next heading that will be visited
          (setq level current-level)
          ;; save the tags that might apply to potential children of the current heading
          (push (-concat (-first-item tags) delta-tags) tags)
          ;; return the heading and inherited tags
          (-concat (list heading)
                   (-first-item tags)))))))


(defun pvv-elfeed-autotag-filter-relevant (list)
  "Filter relevant entries from the LIST."
  (-filter
   (lambda (entry)
     (and
      (string-match "\\(http\\|entry-title\\|feed-url\\)" (car entry))
      (not (member (intern pvv-elfeed-autotag-ignore-tag) entry))))
   list))


(defun pvv-elfeed-autotag-cleanup-headlines (headlines tree-id)
  "In all HEADLINES given remove the TREE-ID."
  (mapcar (lambda (e) (delete tree-id e)) headlines))


(defun pvv-elfeed-autotag-import-headlines-from-files (files tree-id)
  "Visit all FILES and return the headlines stored under tree tagged TREE-ID or with the \":ID:\" TREE-ID in one list."
  (-distinct (-mapcat (lambda (file)
                        (with-current-buffer (find-file-noselect (expand-file-name file))
                          (org-mode)
                          (pvv-elfeed-autotag-cleanup-headlines
                           (pvv-elfeed-autotag-filter-relevant
                            (pvv-elfeed-autotag-convert-tree-to-headlines
                             (pvv-elfeed-autotag-import-trees tree-id)))
                           (intern tree-id))))
                      files)))


(defun pvv-elfeed-autotag-convert-headline-to-tagger-params (tagger-headline)
  "Add new entry hooks for tagging configured with the found headline in TAGGER-HEADLINE."
  (list
   (or
    (when (s-starts-with? "entry-title:" (car tagger-headline))
      (s-trim (s-chop-prefix "entry-title:" (car tagger-headline))))
    (when (s-starts-with? "feed-url:" (car tagger-headline))
      (s-trim (s-chop-prefix "feed-url:" (car tagger-headline)))))
   (cdr tagger-headline)))

(defun pvv-elfeed-autotag-export-entry-hook (tagger-params)
  "Export TAGGER-PARAMS to the proper `elfeed' structure."
  ;; TODO learn how to do this elisp way
  (when (s-starts-with? "entry-title" (car tagger-params))
    (add-hook 'elfeed-autotag-new-entry-hook
              (elfeed-make-tagger
               :entry-title (nth 0 tagger-params)
               :add (nth 1 tagger-params))))
  (when (s-starts-with? "feed-url" (car tagger-params))
    (add-hook 'elfeed-autotag-new-entry-hook
              (elfeed-make-tagger
               :feed-url (nth 0 tagger-params)
               :add (nth 1 tagger-params)))))

(defun pvv-elfeed-autotag-export-feed (headline)
  "Export HEADLINE to the proper `elfeed' structure."
  (add-hook 'elfeed-autotag-new-entry-hook
            (elfeed-make-tagger
             :feed-url (nth 0 headline)
             :add (nth 1 headline)))

  (if (and (stringp (car (last headline)))
           (> (length headline) 1))
      (progn
        (let ((feed (elfeed-db-get-feed (car headline))))
          (setf (elfeed-meta feed :title) (car (last headline)))
          (elfeed-meta feed :title)))))

(defun pvv-elfeed-autotag-filter-taggers (headlines)
  "Filter tagging rules from the HEADLINES in the tree."
  (-non-nil (-map
             (lambda (headline)
               (or
                (when (s-starts-with? "entry-title" (car headline)) headline)
                (when (s-starts-with? "feed-url" (car headline)) headline)))
             headlines)))

(defun pvv-elfeed-autotag-filter-subscriptions (headlines)
  "Filter subscriptions to rss feeds from the HEADLINES in the tree."
  (-non-nil (-map
             (lambda (headline)
               (let* ((text (car headline))
                      (link-and-title (s-match "^\\[\\[\\(http.+?\\)\\]\\[\\(.+?\\)\\]\\]" text))
                      (hyperlink (s-match "^\\[\\[\\(http.+?\\)\\]\\(?:\\[.+?\\]\\)?\\]" text)))
                 (cond ((s-starts-with? "http" text) headline)
                       (link-and-title (-concat (list (nth 1 hyperlink))
                                                (cdr headline)
                                                (list (nth 2 link-and-title))))
                       (hyperlink (-concat (list (nth 1 hyperlink)) (cdr headline))))))
             headlines)))

(defun pvv-elfeed-autotag-process (files tree-id)
  "Process headlines and taggers from FILES with org headlines with TREE-ID."

  ;; Warn if configuration files are missing
  (-each files 'pvv-elfeed-autotag-check-configuration-file)

  ;; Clear elfeed structures
  (setq elfeed-autotag-new-entry-hook nil)

  ;; Convert org structure to elfeed structure and register taggers
  (let* ((headlines (pvv-elfeed-autotag-import-headlines-from-files files tree-id))
         (feeds (pvv-elfeed-autotag-filter-subscriptions headlines))
         (taggers (pvv-elfeed-autotag-filter-taggers headlines))
         ;; (elfeed-taggers (-map 'pvv-elfeed-autotag-convert-headline-to-tagger-params taggers))
         ;; (elfeed-tagger-hooks (-map 'pvv-elfeed-autotag-export-entry-hook elfeed-taggers))
         )
    (-each feeds 'pvv-elfeed-autotag-export-feed)
    (-each taggers 'pvv-elfeed-autotag-export-entry-hook))

  (elfeed-log 'info "elfeed-autotag loaded %i rules"
           (length elfeed-autotag-new-entry-hook)))

(defun elfeed-autotag-run-new-entry-hook (entry)
  "Run ENTRY through elfeed-autotag taggers."
  (--each elfeed-autotag-new-entry-hook
    (funcall it entry)))

;;;###autoload
(defun elfeed-autotag ()
  "Setup auto-tagging rules."
  (interactive)
  (elfeed-log 'info "elfeed-autotag initialized")
  (defadvice elfeed (before configure-elfeed activate)
    "Load all feed settings before elfeed is started."
    (pvv-elfeed-autotag-process pvv-elfeed-autotag-files pvv-elfeed-autotag-tree-id))
  (add-hook 'elfeed-new-entry-hook #'elfeed-autotag-run-new-entry-hook))

(provide 'elfeed-autotag)
;;; elfeed-autotag.el ends here
