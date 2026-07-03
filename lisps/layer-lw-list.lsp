;;; Layer and lineweight list to drawing
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2000-06-27
;;;
(vl-load-com)
(defun ax:layer-lw-list (/ layer lw lst)
  (vlax-for layer (vla-get-Layers
                    (vla-get-ActiveDocument
                      (vlax-get-acad-object)
                    )
                  )
    (setq lw (vla-get-lineweight layer))
    (if (= lw -3)
      (setq lw 0.25 lwt "Default")
      (setq lw (/ lw 100.0) lwt (strcat (rtos lw 2 2) " mm"))
    )
    (setq lst (cons
                (list
                  (vla-get-name layer)
                  lw
                  lwt
                ) lst))
  )
  (vl-sort lst
           (function (lambda (e1 e2)
                       (< (strcase (car e1)) (strcase (car e2)))
                     )
           )
  ) 
)

(defun c:layer-lw-list (/ p row y ts xd plinewidold)
  (setq p (getpoint "Specify top left point of list: "))
  (setq ts (getvar "textsize"))
  (setq y (cadr p))
  (setq xd (* ts 15)) ; dist between columns
  (setq plinewidold (getvar "PLINEWID"))
  (if p
    (foreach row (ax:layer-lw-list)
      (command "text" p "" "" (car row))
      (setvar "PLINEWID" (* (/ ts 2.11) (cadr row)))
      (command "pline"
               (list (+ (car p) (* 0.9 xd)) (+ (cadr p) (/ ts 2.0)) (caddr p))
               (list (+ (car p) (* 0.98 xd)) (+ (cadr p) (/ ts 2.0)) (caddr p))
               ""
      )
      (command "text" (list (+ (car p) xd) (cadr p) (caddr p)) "" "" (caddr row))
      (setq y (- y (* ts 1.66667)))
      (setq p (list (car p) y (caddr p)))
    )
  )
  (setvar "PLINEWID" plinewidold)
  (princ)
)
