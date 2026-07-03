;;; c:ChangeNoPlottableLayers
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com

;;; 2000-03-13
;;; 2003-01-08 - Handle frozen/off/locked defpoints layer by thawing/on/unlocking it
;;; Tested on AutoCAD 2000, 2002
;;;
;;; This is useful when you want to save a file to
;;; r14 or older.
;;; It tries to move all entities from layers that
;;; are not plottable to layer defpoints.
;;;
(vl-load-com)
(defun c:ChangeNoPlotLayers (/ ad layer ss)
  (layer-set "defpoints")
  (setq ad (vla-get-ActiveDocument (vlax-get-Acad-Object)))
  (vlax-for layer (vla-get-Layers ad)
    (cond
      ((eq (vla-get-plottable layer) :vlax-true))
      ((/= (vla-get-name layer) "defpoints")
       (vla-put-Freeze layer :vlax-false)
       (vla-put-Lock layer :vlax-false)
       (GlobalChangeLayer (vla-get-name layer) "defpoints")
      )
    )
  )
  (command "._regenall")
  (princ)
)

;;; By Tony Tanzillo ?
(defun GlobalChangeLayer (oldlayer newlayer / ent old new)
   (setq old (cons 8 (getLayerName oldlayer)))
   (setq new (cons 8 (getLayerName newlayer)))
   (BlockEntityIterator
     '(lambda (e) 
         (changeLayer e old new)
      )
   )
   (setq ent (entnext))
   (while ent 
      (changeLayer ent old new)
      (setq ent (entnext ent))
   )
)

(defun getLayerName (name)
   (cdr (assoc 2 (tblsearch "layer" name)))
)

(defun BlockEntityIterator (bei_Func / bei_block bei_ent)
   (while (setq bei_block (tblnext "block" (not bei_block)))
      (setq bei_ent (cdr (assoc -2 bei_block)))
      (while bei_ent
         (apply bei_func (list bei_ent))
         (setq bei_ent (entnext bei_ent))
      )
   )
)

(defun ChangeLayer (ent old new / data)
   (setq data (entget ent))
   (if (equal (assoc 8 data) old)
      (entmod (subst new old data))
   )
)

; Not by me
(defun layer-set (layer / e d c f)
  (cond
    ; _________________
    ;
    ; layer exists
    ; ensure "settable"
    ; set current
    ; _________________

    ( (setq e (tblobjname "layer" layer))
      (setq
        d (entget e)         ; data 
        c (cdr (assoc 62 d)) ; color 
        f (cdr (assoc 70 d)) ; flags 
      )
      (if (minusp c)
        ; layer is off, force abs of color
        (setq d (subst (cons 62 (abs c)) (assoc 62 d) d))
      )
      (if (eq 1 (logand 1 f))
        ; layer is frozen, mask off 1
        (setq f (boole 6 f 1))
      )
      (if (eq 4 (logand 4 f))
        ; layer is locked, mask off 4
        (setq f (boole 6 f 4))
      )
      ; did we change the flag value?
      (if (not (eq f (cdr (assoc 70 d))))
        (setq d (subst (cons 70 f) (assoc 70 d) d))
      )
      ; did we change the dxf data at all?
      (if (not (equal d (entget e)))
        (entmod d)
      )
      ; set layer current, return 
            ; layer name to calling function
      (setvar "clayer" layer)
    )
    ; _____________________
    ;
    ; layer doesn't exist,
    ; symbol name is valid,
    ; make it / set it
    ; _____________________

    ( (snvalid layer)
      (if 
        (entmake
          (list
           '(0 . "LAYER")
           '(100 . "AcDbSymbolTableRecord")
           '(100 . "AcDbLayerTableRecord")
            (cons 2 layer)
           '(70 . 0)
           '(62 . 7)
           '(6 . "CONTINUOUS")
          )
        )
        ; ______________________________
        ;
        ; if entmake was successful 
        ; set layer current, return 
                ; layer name to calling function
        ; ______________________________

        (setvar "clayer" layer)
      )
    )
    ; _____________________
    ;
    ; layer doesn't exist 
    ; symbol name invalid
    ; return nil to calling 
        ;   function
    ; _____________________

  )
)
