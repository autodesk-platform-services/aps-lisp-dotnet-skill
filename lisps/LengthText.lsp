;;; LengthText.LSP ver 1.0
;;; Command name is LTXT
;;; Select any object with a length and where to place the text
;;; Current unit settings are being used
;;; Sample result: 152
;;; As this is a FIELD it is updated based on the FIELDEVAL
;;; or the settings found in the OPTIONS dialog box
;;; By Jimmy Bergmark
;;; Copyright (C) 2014 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2014-09-14 - First release
(defun Get-ObjectIDx64 (obj / util)
  (setq util (vla-get-Utility
    (vla-get-activedocument (vlax-get-acad-object))))
  (if (= (type obj) 'ENAME)
    (setq obj (vlax-ename->vla-object obj))
  )
  (if (= (type obj) 'VLA-OBJECT)
    (if (> (vl-string-search "x64" (getvar "platform")) 0)
      (vlax-invoke-method
        util "GetObjectIdString" obj :vlax-False)
      (rtos (vla-get-objectid obj) 2 0)
    )
  )
)
;;; Get-CurSpace function
(defun Get-CurSpace (/ ad)
  (setq ad (vla-get-ActiveDocument (vlax-get-acad-object)))
  (if (= 1 (vla-get-activespace ad))
    (vla-get-modelspace ad)
    (if (= (vla-get-mspace ad) :vlax-true)
      (vla-get-modelspace ad)
      (vla-get-paperspace ad)
    )
  )
)
(defun c:LTXT (/ returnOrErr entObject entObjectID InsertionPoint ad
                 propName)
  (vl-load-com)
  (setq returnOrErr
    (vl-catch-all-apply 'entsel (list "Select object: "))
  )
  (if (and (/= returnOrErr nil)
        (/= (type returnOrErr) 'VL-CATCH-ALL-APPLY-ERROR))
    (progn
      (setq entObject (vlax-ename->vla-object (car returnOrErr))
            entObjectID (Get-ObjectIDx64 entObject)
            ad (vla-get-ActiveDocument (vlax-get-acad-object))
      )
  
      ;Check if Length or Circumference property is available:
      (if (vl-catch-all-error-p
            (vl-catch-all-apply 'vla-get-length (list entObject)))
        (if
          (vl-catch-all-error-p
            (vl-catch-all-apply 'vla-get-circumference (list entObject)))
          (progn
            (setq propName nil)
            (princ "\nObject not supported.")
          )
          (setq propName "Circumference")
        )
        (setq propName "Length")
      )
      
      (if propName
        (progn
          (setq returnOrErr
            (vl-catch-all-apply
              'getpoint
              (list "Select point: ")
            )
          )
          (if (and (/= returnOrErr nil)
                   (/= (type returnOrErr) 'VL-CATCH-ALL-APPLY-ERROR))
            (progn
              (setq InsertionPoint (vlax-3D-Point returnOrErr))
              (vla-addMText
                (Get-CurSpace)
                InsertionPoint
                0.0
                (strcat
                  "%%)."
                  propName " \\f \"%lu6\">%"
                )
              )
            )
          )
        )
      )
    )
  )
  (princ)
)
(princ "\nLengthText.LSP by JTB World, use command LTXT.")
(princ)
