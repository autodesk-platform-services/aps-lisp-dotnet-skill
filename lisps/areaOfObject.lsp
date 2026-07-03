;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; returns the area of selected object
;;; Made for AutoCAD 2000
(defun c:areaOfObject (/ en curve area)
  (if (setq en (entsel))
    (progn
      (setq curve (vlax-ename->vla-object (car en)))
      (if
        (vl-catch-all-error-p
          (setq
            area (vl-catch-all-apply 'vlax-curve-getArea (list curve))
          )
        )
         nil
         area
      )
    )
  )
)
