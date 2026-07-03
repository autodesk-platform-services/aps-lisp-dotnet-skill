;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2016 JTB World, All Rights Reserved
;;; Website: http://jtbworld.com
;;; E-mail: info@jtbworld.com

;;; the command name is VPC

;;; About: show the coordinates for the center of the current viewport on command line
;;; if command is run within a viewport in model space it can be run transparently
;;;   for example like this using 'vpc
;;;   Command: LINE
;;;   Specify first point: 'vpc
;;; if command is in paper space it will ask to select viewport and the point will
;;;   be available as last used point and can be used with @ like this:
;;;   Command: LINE
;;;   Specify first point: @

(vl-load-com)

;;; get the viewportcenter old version
(defun viewportcenterold ()
  (vlax-safearray->list
   (vlax-variant-value
     (vla-get-center
       (vla-get-activepviewport
         (vla-get-activedocument
           (vlax-get-acad-object)))))))
; Example of using the variable viewctr           
;(defun c:vpc ()
;  (getvar "viewctr")
;)           
(defun c:vpc (/ viewportcenter ad ss vp ent)
  (defun vpc ()
    (vlax-safearray->list
           (vlax-variant-value
             (vla-get-center
               (if (= (getvar "tilemode") 0)
               (vla-get-activepviewport
                 ad
               )
                 (vla-get-activeviewport
                 ad
               )
                 )
             )
           )
         ))
  (setq ad (vla-get-activedocument
                   (vlax-get-acad-object)
                 ))
   (if (= (getvar "tilemode") 0)
    (if (= (getvar "cvport") 1)
      (if (/= (setq ss (ssget ":E:S" '((0 . "VIEWPORT")))) nil)
        (if (/= 1 (logand 1 (cdr (assoc 90 (setq vp (entget (setq ent (ssname ss 0))))))))
          (progn
            (command "._mspace")
            (setvar "cvport" (cdr (assoc 69 vp)))
            (setq viewportcenter (vpc))
            (command "._pspace")
          )
          (princ "\n Command not allowed in perspective view.")
        )
        (princ " No viewport found.")
      )
      (progn
        (setq ent (vlax-vla-object->ename
                    (vla-get-activepviewport
                      (vla-get-activedocument (vlax-get-acad-object)))))
        (if (/= 1 (logand 1 (cdr (assoc 90 (entget ent)))))
          (setq viewportcenter (trans (vpc) 3 2))
          (princ "\n Command not allowed in perspective view.")
        )
      )
    )
    (setq viewportcenter (vpc)) 
  )
  (setvar "LASTPOINT" viewportcenter)
  (list (car viewportcenter) (cadr viewportcenter))
)

(princ)
