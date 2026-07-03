;;; tsh0.LSP ver 1.0
;;; Set all text style's height to 0
;;; By Jimmy Bergmark
;;; Copyright (C) 2008 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2008-03-08 - First release
;;; Tested on AutoCAD 2009
;;; should be working on older versions too.

(defun C:TSH0 (/ ad style oldcmdecho)
  (vl-load-com)
  (setq ad (vla-get-ActiveDocument (vlax-get-Acad-Object)))
  (princ "Listed text style's height have been set to 0:")
  (vlax-for style (vla-get-TextStyles ad)
    (if (and (/= (wcmatch (vla-get-Name style) "*|*") T) (/= (vla-get-Height style) 0.0))
      (progn
       (vla-put-Height style 0.0)
       (princ "\n")
       (princ (vla-get-Name style))
      )
    )
  )
  (setq oldcmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (command "._regenall")
  (setvar "cmdecho" oldcmdecho)
  (princ)
)

(princ "\nRun with the TSH0 command")
(princ)
