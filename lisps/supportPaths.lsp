;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; Save and loads support paths to a text file
;;;
;;; Change the path as wished

(defun C:saveSupportPaths (/ files paths f)
  (vl-load-com)
  (setq files (vla-get-files (vla-get-preferences (vlax-get-acad-object))))
  (setq paths (vla-get-supportpath files))
  (setq f (open "r:\\paths.txt" "w"))
  (write-line paths f)
  (close f)
  (princ)
)

(defun C:loadSupportPaths (/ files paths f)
  (vl-load-com)
  (setq files (vla-get-files (vla-get-preferences (vlax-get-acad-object))))
  (setq f (open "r:\\paths.txt" "r"))
  (setq paths (read-line f))
  (close f)
  (vla-put-supportpath files paths)
  (princ)
)
