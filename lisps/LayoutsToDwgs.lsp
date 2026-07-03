;;;
;;;    LayoutsToDwgs.lsp
;;;    Created 2000-03-27

;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2016 JTB World, All Rights Reserved
;;; Website: http://jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; 2003-12-12 Sets UCS to world in model space
;;;            to avoid problem with wblock
;;; 2011-06-06 Excludes empty layouts
;;; 2012-06-01 Handle Map prompt with WBLOCK
;;;             Include AutoCAD Map information in the export? [Yes/No] :
;;; 2013-03-04 Added _ on some commands to internationalize it
;;; 2015-12-01 Updated for AutoCAD 2015 and 2016
;;; 2016-10-26 Modified to also allow suffix
;;;
;;;    For AutoCAD 2000, 2000i, 2002, 2004, 2005, 
;;;    2006, 2007, 2008, 2009, 2011, 2012, 2013, 2014, 2015, 2016 and newer
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Creates separate drawings of all layouts.
;;;   The new drawings are saved to the current drawings path
;;;   and overwrites existing drawings.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun c:LayoutsToDwgs (/ errexit undox olderr oldcmdecho oldexpert oldcmddia fn path
                          msg msg2 fileprefix filesuffix i j)

  (defun errexit (s)
    (princ "\nError:  ")
    (princ s)
    (restore)
  )

  (defun undox ()
    (command "._undo" "_E")
    (setvar "cmdecho" oldcmdecho)
    (setvar "expert" oldexpert)
    (setvar "cmddia" oldcmddia)
    (setq *error* olderr)
    (princ)
  )

  (setq olderr  *error*
        restore undox
        *error* errexit
  )
  (setq oldcmdecho (getvar "cmdecho"))
  (setq oldexpert (getvar "expert"))
  (setq oldcmddia (getvar "cmddia"))
  (setvar "cmdecho" 0)
  (setvar "expert" 2)
  (setvar "cmddia" 0)
  (defun DelAllLayouts (Keeper / TabName)
    (vlax-for Layout
                     (vla-get-Layouts
                       (vla-get-activedocument (vlax-get-acad-object))
                     )
      (if
        (and
          (/= (setq TabName (strcase (vla-get-name layout))) "MODEL")
          (/= TabName (strcase Keeper))
        )
         (vla-delete layout)
      )
    )
  )

  (vl-load-com)
  (setq msg "" msg2 "" i 0 j 0)
  (command "._undo" "_BE")
  (setq fileprefix (getstring "Enter filename prefix: "))
  (setq filesuffix (getstring "Enter filename suffix: "))
  (foreach lay (layoutlist)
    (if (and (/= lay "Model") (> (vla-get-count (vla-get-block (vla-Item (vla-get-Layouts (vla-get-activedocument (vlax-get-acad-object))) lay))) 1))
      (progn
        (command "_.undo" "_M")
        (DelAllLayouts lay)
        (setvar "tilemode" 1)
        (command "_.ucs" "_w")
        (setvar "tilemode" 0)
        (setq path (getvar "DWGPREFIX"))
        (setq fn (strcat path fileprefix lay filesuffix ".dwg"))
        (if (findfile fn)
          (progn
            (command "_.-wblock" fn)
            (if (equal 1 (logand 1 (getvar "cmdactive")))
              (progn
                (setq i (1+ i) msg (strcat msg "\n" fn))
                (command "*")
              )
              (setq j (1+ j) msg2 (strcat msg2 "\n" fn))
            )
          )
          (progn
            (command "_.-wblock" fn "*")
            (setq i (1+ i)  msg (strcat msg "\n" fn))
          )
        )
        (if (equal 1 (logand 1 (getvar "cmdactive")))
          ; Include AutoCAD Map information in the export?
          ; If you don't want to include Map information in the new files change "_Y" to "_N" below
          (command "_Y")
        )
        (command "_.undo" "_B")
      )
    )
  )
  (if (/= msg "")
    (progn
      (if (= i 1)
        (prompt "\nFollowing drawing was created:")
        (prompt "\nFollowing drawings were created:")
      )
      (prompt msg)
    )
  )
  (if (/= msg2 "")
    (progn
      (if (= j 1)
        (prompt "\nFollowing drawing was NOT created:")
        (prompt "\nFollowing drawings were NOT created:")
      )
      (prompt msg2)
    )
  )
  (command "._undo" "_E")
  (textscr)
  (restore)
  (princ)
)
(princ)
