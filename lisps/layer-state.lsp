;;; List layers according to state
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2000-05-15
;;;
;;; Argument: state
;;;             1  frozen
;;;             2  thawed
;;;             3  on
;;;             4  off
;;;             5  lock
;;;             6  not locked
;;;             7  plottable
;;;             8  not plottable
;;; Example: (layer-state 1)
;;; Return values: list of layers
(vl-load-com)
(defun layer-state (state / typ names tf skip)
  (setq names nil)
  (vlax-for layer (vla-get-Layers
                    (vla-get-ActiveDocument
                      (vlax-get-acad-object)
                    )
                  )
    (setq skip nil)
    (cond
      ((= 1 state) (setq typ (vla-get-freeze layer) tf :vlax-true))
      ((= 2 state) (setq typ (vla-get-freeze layer) tf :vlax-false))
      ((= 3 state) (setq typ (vla-get-layeron layer) tf :vlax-true))
      ((= 4 state) (setq typ (vla-get-layeron layer) tf :vlax-false))
      ((= 5 state) (setq typ (vla-get-lock layer) tf :vlax-true))
      ((= 6 state) (setq typ (vla-get-lock layer) tf :vlax-false))
      ((= 7 state) (setq typ (vla-get-plottable layer) tf :vlax-true))
      ((= 8 state) (setq typ (vla-get-plottable layer) tf :vlax-false))
      (t (setq skip T))
    )
    (if (and (null skip) (eq typ tf))
      (setq names (cons (vla-get-name layer) names))
    )
  )
  (reverse names)
)
