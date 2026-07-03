;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; Example of inserting a block with ActiveX in modelspace
;;;
;;; (ax:insert (vla-get-activedocument (vlax-get-acad-object))
;;;            "r:\\projekt\\4045\\B\\revtext3.dwg" "0"
;;;            '(160 120 0) 1 1 1 0)
(vl-load-com)
(defun ax:insert (doc bn layer ins x y z rt)
  (setq layer (vla-item (vla-get-layers doc) layer))
  ; put the layer on
  (vla-put-LayerOn layer 1)
  ; cannot thaw if active layer is 0
  (vl-catch-all-apply 'vla-put-Freeze (list layer :vlax-false))
  ; put active layer
  (vla-put-activeLayer doc layer)
  (setq ins (list->variantArray ins))
  (vla-insertblock (vla-get-modelspace doc) ins bn x y z rt)
)

(defun list->variantArray (ptsList / arraySpace sArray)
    (setq arraySpace
      (vlax-make-safearray
        vlax-vbdouble
        (cons 0 (- (length ptsList) 1))
      )
    )
    (setq sArray (vlax-safearray-fill arraySpace ptsList))
    (vlax-make-variant sArray)
  )
