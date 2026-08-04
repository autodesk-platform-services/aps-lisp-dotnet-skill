;COMBINED DIALOG EDITOR FOR BLOCKS,ATTDEFS,TEXT AND DIMENSIONS.
;stext changed by A.BATTS for multiple selection
;updated to work with mtext and multileaders as well as AutoCAD 2017 by JTB World Inc. / Jimmy Bergmark http://jtbworld.com

(defun cstxt (); (/ sp e)
;------
; (while (not e)
;  (setq e
;   (entsel "Select Object: ")))
; (if e (setq sp (cadr e)
;     e (entget (car e))))
;------
 (cond
  ((member
    (field 0 e) '("MTEXT" "TEXT" "ATTDEF" "MULTILEADER"))
   (command "_.textedit" sp ""))
  ((and
    (= (field 0 e) "INSERT")
    (= (field 66 e) 1))
  (command "_.ddatte" sp))
 ((= (field 0 e) "DIMENSION")
  (ddedim e))
   (T
    (prompt "Not Text, Mtext, Attdef, Multileader, Dimension or Block with Attributes....\n"))
   )
 (princ)
)
(defun ddedim (e / dcl_id dimtxt editxt)
 (setq dcl_id (load_dialog "MSTXT.DCL"))
 (if (not (new_dialog "DDEDIM" dcl_id)) (exit))
 (if (member (field 0 e) '("DIMENSION"))
  (progn
   (setq dimtxt "")
   (set_tile "DEFTXT" (rtos (actual e)))
   (set_tile "USRTXT" (field 1 e))
   (set_tile (cond
    ((= (field 1 e) ""    )    "DEF")
    (t (mode_tile "USRTXT" 2) "USR")) (itoa 1))
   (action_tile "DEF" "(setq dimtxt \"\")" )
   (action_tile "USR" "(setq dimtxt (get_tile \"USRTXT\"))
   (mode_tile \"USRTXT\" 2)"    )
   (action_tile "USRTXT" "(setq editxt $value dimtxt editxt)
   (set_tile \"USR\" (itoa 1))" )
   (if (eq (start_dialog) 1) (echg e 1 dimtxt))
   (unload_dialog dcl_id)
  )
 )
(princ)
)
(defun ECHG (ent fld val)
 (entmod (subst (cons fld val) (assoc fld ent) ent))
 )
 (defun FIELD (val e)
  (cdr (assoc val e))
 )
 (defun actual
  (e / dt dlf sp ep hyp ang pro)
  (setvar "cmdecho" 0)
  (setq sp (field 13 e)
        ep (field 14 e)
    dt (logand 127 (field 70 e)) 
    dlf (if
      (= (field 3 e) "*UNNAMED")
      (getvar "dimlfac")
      (field 144
       (tblsearch
        "dimstyle" (field 3 e))))
       hyp (distance sp ep)
       ang
        (if (= dt 1)
          0 (- (angle sp ep)
          (field 50 e))))
   (abs (* (cos ang) hyp dlf))
 ; returns projected length
)
(defun c:txt ()
;   (COMMAND "'ZOOM" "1X")
   (setq p (ssget))                  ; Select objects
   (if p (progn                      ; If any objects selected
      (setq l 0 n (sslength p))
      (while (< l n)                 ; For each selected object...
         (setq e (entget (setq sp (ssname p l))))
         (cstxt)
         (setq l (1+ l))
      )
   ))
   (princ)

)
(princ "\n\tMSTXT Editor Loaded...........................Start command with TXT.")
(princ)


