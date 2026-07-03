;;;---------------------------------------------------------------------------;
;;;
;;; vpsel.lsp
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; 2000-04-14 - First release
;;; Tested on AutoCAD 2000
;;;
;;;---------------------------------------------------------------------------;
;;;  DESCRIPTION
;;;
;;;  Select all visible objects in selected or active paperspace viewport
;;;  Works transparently when in modelspace and for polygonal viewports too
;;;  Example1: ERASE ALL R 'VPC >>> Erase all in model except what is visible
;;;  Example2: (command "erase" "all" "r" (c:vpc) "")
;;;  Example3: VPC ERASE >>> VPC is run previous the command and the objects
;;;                            are also in previous selection set
;;;
;;;  c:vpc - select all visible objects with crossing in viewport
;;;  c:vpw - select all visible objects with window in viewport
;;;---------------------------------------------------------------------------;

(defun c:vpc ()
  (vpsel "C")
  (princ)
)

(defun c:vpw ()
  (vpsel "W")
  (princ)
)

(defun dxf (n ed) (cdr (assoc n ed)))

(defun vpsel (typ   /     ad    ss    ent   vpno  ok    vpbl  vpur
              msbl  msur  msul  mslr  ss1   pl    nlist x     n
             )
  (vl-load-com)
  (setq ok t)
  (if (= (getvar "tilemode") 0)
    (progn
      (setq ad (vla-get-activedocument (vlax-get-acad-object)))
      (if (= (getvar "cvport") 1)
        (if (and (= (getvar "cmdactive") 0)
                 (/= (setq ss (ssget ":E:S" '((0 . "VIEWPORT")))) nil)
            )
          (progn
            (setq ent (ssname ss 0))
            (setq vpno (dxf 69 (entget ent)))
            (vla-Display (vla-get-activepviewport ad) :vlax-true)
            (vla-put-mspace ad :vlax-true)
            (setvar "cvport" vpno)
          )
          (progn
            (setq ok nil)
          )
        )
        (setq ent (vlax-vla-object->ename (vla-get-activepviewport ad)))
      )
      (if (and ok (/= 1 (logand 1 (dxf 90 (setq ed (entget ent))))))
        (progn
          (if (= (vla-get-clipped (vlax-ename->vla-object ent))
                 :vlax-false
              )
            (progn
              (vla-getboundingbox
                (vla-get-activepviewport ad)
                'vpbl
                'vpur
              )
              (setq msbl (trans (vlax-safearray->list vpbl) 3 2))
              (setq msur (trans (vlax-safearray->list vpur) 3 2))
              (setq msul (list (car msbl) (cadr msur)))
              (setq mslr (list (car msur) (cadr msbl)))
              (setq ss1
                     (ssget (strcat typ "P") (list msbl msul msur mslr))
              )
            )
            (progn
              (setq pl (entget (dxf 340 (entget ent))))
              (setq nlist nil)
              (foreach x pl
                (if (eq 10 (car x))
                  (setq nlist (cons (trans (cdr x) 3 2) nlist))
                )
              )
              (setq ss1 (ssget (strcat typ "P") nlist))
            )
          )
          (sssetfirst nil ss1)
          (if ss1
            (setq n (sslength ss1))
            (setq n 0)
          )
          (princ n)
          (princ " found ")
          (if (and ss1 (= (getvar "cmdactive") 1))
            ss1
          )
        )
      )
    )
  )
  (setq ss nil ss1 nil)
)

(princ)
