;;; viewsIO.lsp
;;;
;;; Export and import views
;;;
;;; c:ExportViews
;;; c:ImportViews
;;; c:-ExportViews
;;; c:-ImportViews
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2008 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; 2000-06-27
;;;
;;; Tested on AutoCAD 2000-2004
;;;
;;; Modified by Marko Ribar 2012-04-21
;;;
;;; Tested on AutoCAD 2012

(vl-load-com)

(defun c:ExportViews (/ fn)
  (if (setq fn
             (getfiled "Export views to"
                       (strcat (vl-filename-base (getvar "dwgname")) ".txt")
                       "txt"
                       1
             )
      )
    (ExportViews fn)
  )
  (princ)
)

(defun c:ImportViews (/ fn)
  (if (setq fn
             (getfiled "Import views from"
                       (strcat (vl-filename-base (getvar "dwgname")) ".txt")
                       "txt"
                       16
             )
      )
    (ImportViews fn)
  )
  (princ)
)

(defun c:-ExportViews (/ fn x)
  (setq fn (strcat (vl-filename-base (getvar "dwgname")) ".txt"))
  (if (setq fn
             (findfile
               (if (= ""
                      (setq nn (getstring
                                 T
                                 (strcat "Enter filename : "
                                 )
                               )
                      )
                   )
                 fn
                 nn
               )
             )
      )
    (progn
      (initget "Yes No")
      (setq x (getkword "\nFile exists.  Overwrite? [Yes/No] : "))
      (if (= x "Yes") (ExportViews fn))
    )
    (princ "\nFile not found.")
  )
  (princ)
)

(defun c:-ImportViews (/ fn)
  (setq fn (strcat (vl-filename-base (getvar "dwgname")) ".txt"))
  (if (setq fn
             (findfile
               (if (= ""
                      (setq nn (getstring
                                 T
                                 (strcat "Enter filename : "
                                 )
                               )
                      )
                   )
                 fn
                 nn
               )
             )
      )
    (ImportViews fn)
    (princ "\nFile not found.")
  )
  (princ)
)

(defun ExportViews (fn / e tl f ed)
  (while (setq e (tblnext "VIEW" (null e)))
    (setq tl (cons (cdr (assoc 2 e)) tl))
  )
  (setq f (open fn "w"))
  (if f
    (progn
      (princ "Following views exported:\n")
      (foreach view tl
        (setq ed (entget (tblobjname "view" view)))
        (if (assoc 348 ed) (prin1 (cons (cons 0 "VISUALSTYLE")
 (member (assoc 100 (entget (cdr (assoc 348 ed))))
 (entget (cdr (assoc 348 ed))))) f))
        (if (assoc 348 ed) (princ "\n" f))
        (prin1 (cons (cons 0 "VIEW") (if (assoc 348 ed) 
(reverse (cdr (reverse (member (assoc 100 ed) ed))))
 (member (assoc 100 ed) ed))) f)
        (princ "\n" f)
        (prin1 view)
        (terpri)
      )
      (close f)
    )
  )
)

(defun ImportViews (fn / tl assoc348 assoc330 en330 en348 f)
  (setq f (open fn "r"))
  (if f
    (progn
      (princ "Following views imported:\n")
      (while (setq tl (read-line f))
        (setq tl (read tl))
        (if (eq (cdr (assoc 0 tl)) "VIEW") 
          (progn
            (entmake tl)
            (print (cdr (assoc 2 tl)))
          )
        )
        (if (eq (cdr (assoc 0 tl)) "VISUALSTYLE")
          (progn
	    (vlax-for di (vla-get-dictionaries 
(vla-get-activedocument (vlax-get-acad-object))) 
(if (eq (vl-catch-all-apply 'vla-get-name (list di)) "ACAD_VISUALSTYLE")
 (setq en330 (vlax-vla-object->ename di))))
            (setq assoc330 (cons 330 en330))
            (setq assoc348 (cons 348 (setq en348 (entmakex tl))))
	    (entmod (subst assoc330 (assoc 330 (entget en348)) (entget en348)))
            (setq tl (read-line f))
            (setq tl (read tl))
            (setq tl (reverse (cons assoc348 (reverse tl))))
            (entmake tl)
            (print (cdr (assoc 2 tl)))
          )
        )
      )
      (close f)
    )
  )
)

(princ)
