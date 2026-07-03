;;;---------------------------------------------------------------------------;
;;;
;;; VPlayers.lsp
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; 2000-09-07 - First release
;;; Tested on AutoCAD 2000
;;;
;;;---------------------------------------------------------------------------;
;;;  DESCRIPTION
;;;
;;;  c:SaveVPlayers - Save frozen viewport layers to file
;;;  c:LoadVPlayers - Load and restore frozen viewport layers from file
;;;  c:CopyVPlayers - Select one viewport and get the layersettings
;;;                   then select the destination viewport(s) to inherit these
;;;---------------------------------------------------------------------------;

(defun dxf (n ed) (cdr (assoc n ed)))
(vl-load-com)
;;; return a list of frozen layers in current viewport
;;; ex. (viewport-frozen-layer-list) -> ("Layer3" "Layer4")
;;; alt. with Express Tools (ACET-VIEWPORT-FROZEN-LAYER-LIST (ACET-CURRENTVIEWPORT-ENAME))
(defun viewport-frozen-layer-list (/ cvp)
  (if (= 0 (getvar "tilemode"))
    (if (/= 1 (setq cvp (getvar "cvport")))
      (apply
        'append
        (mapcar
          '(lambda (x)
             (if (= 1003 (car x))
               (list (cdr x))
             )
           )
          (cdadr
            (assoc
              -3
              (entget
                (ssname
                  (ssget "_X"
                         (list (cons 69 cvp) (cons 410 (getvar "ctab")))
                  )
                  0
                )
                '("acad")
              )
            )
          )
        )
      )
    )
  )
)

(defun GetVPlayers (/ ss ent vpno)
  (command "._pspace")
  (princ "\nSelect source viewport: ")
  (setq ss (ssget ":E:S" '((0 . "VIEWPORT"))))
  (if ss
    (progn
      (setq ent (ssname ss 0))
      (setq ss nil)
      (setq vpno (dxf 69 (entget ent)))
      (command "._mspace")
      (setvar "cvport" vpno)
      (viewport-frozen-layer-list)
    )
  )
)


(defun c:SaveVPlayers (/ fn oldcmdecho VAL f *error* restore layers)
  (defun *error* (str)
    (restore)
    (if str
      (prompt (strcat "Error: " str))
    )
    (princ)
  )
  (defun restore ()
    (command "._undo" "_E")
    (setvar "cmdecho" oldcmdecho)
  )

  (setq oldcmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (command "._UNDO" "_BE")
  (cond
    ((not (equal 0 (getvar "tilemode")))
     (princ
       "\n  Command not allowed unless TILEMODE is set to 0  "
     )
    )
    ((> 2
        (sslength
          (ssget "_x"
                 (list (cons 0 "VIEWPORT") (cons 410 (getvar "ctab")))
          )
        )
     )
     (princ "\n  Command works with one or more viewports only  "
     )
    )
    ((not (setq fn
                 (getfiled "Save ViewPort layer list as"
                           (vl-filename-base (getvar "dwgname"))
                           "vpl"
                           1
                 )
          )
     )
    )
    ((not (setq f (open fn "w")))
     (princ "\n  Cannot write to file!")
    )
    (T
     (setq layers (GetVPlayers))
     (if layers
       (prin1 layers f)
       (princ "\n  There are no frozen VP layers.")
     )
     (command "._pspace")
     (close f)
    )
  )
  (restore)
  (princ)
)

(defun PutVPlayers (layers / VAL ss)
  (if layers
    (progn
      (princ "\nSelect destination viewport: ")
      (command "._pspace")
      (setq ss (ssget ":E" '((0 . "VIEWPORT"))))
      (if ss
        (progn
          (command "_.vplayer" "_thaw" "*" "_select" ss "")
          (foreach VAL layers (command "_freeze" VAL "_select" ss ""))
          (setq ss nil)
          (command "")
        )
      )
    )
  )
)

(defun c:LoadVPlayers (/ oldcmdecho fn tl lst *error* restore)
  (defun *error* (str)
    (restore)
    (if str
      (prompt (strcat "Error: " str))
    )
    (princ)
  )
  (defun restore ()
    (command "._undo" "_E")
    (setvar "cmdecho" oldcmdecho)
  )

  (setq oldcmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (command "._UNDO" "_BE")
  (cond
    ((not (equal 0 (getvar "tilemode")))
     (princ
       "\n  Command not allowed unless TILEMODE is set to 0  "
     )
    )
    ((> 2
        (sslength
          (ssget "_x"
                 (list (cons 0 "VIEWPORT") (cons 410 (getvar "ctab")))
          )
        )
     )
     (princ "\n  Command works with one or more viewports only  "
     )
    )
    ((not (setq fn
                 (getfiled "Open ViewPort layer list"
                           (vl-filename-base (getvar "dwgname"))
                           "vpl"
                           0
                 )
          )
     )
    )
    ((not (setq f (open fn "r")))
     (princ "\n  Cannot read file!")
    )
    (T
     (setq lst (read (read-line f)))
     (if (= (type lst) 'LIST)
       (PutVPlayers lst)
     )
     (command "._pspace")
     (close f)
    )
  )
  safe
  (restore)
  (princ)
)

(defun c:CopyVPlayers (/ oldcmdecho *error* restore layers)
  (defun *error* (str)
    (restore)
    (if str
      (prompt (strcat "Error: " str))
    )
    (princ)
  )
  (defun restore ()
    (command "._undo" "_E")
    (setvar "cmdecho" oldcmdecho)
  )

  (setq oldcmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (command "._UNDO" "_BE")
  (cond
    ((not (equal 0 (getvar "tilemode")))
     (princ
       "\n  Command not allowed unless TILEMODE is set to 0  "
     )
    )
    ((> 3
        (sslength
          (ssget "_x"
                 (list (cons 0 "VIEWPORT") (cons 410 (getvar "ctab")))
          )
        )
     )
     (princ "\n  Command works with two or more viewports only  "
     )
    )
    (T
     (setq layers (GetVPlayers))
     (if layers
       (PutVPlayers layers)
       (princ "\n  There are no frozen VP layers.")
     )
     (command "._pspace")
    )
  )
  (restore)
  (princ)
)

(princ)
