;;; AreaText.LSP ver 4.0;;; Command names are AT, ATC, ATM;;; AT command: Select a polyline and where to place the text;;; ATC command: Select a polyline and add the text at the geo center of the selected object;;; ATM command: Select multiple objects and add the text at the boundary box center
;;; Sample result: 2888.89 SQ. FT.
;;; As this is a FIELD it is updated based on the FIELDEVAL
;;; or the settings found in the OPTIONS dialog box

;;; By Jimmy Bergmark
;;; Copyright (C) 2007-2018 JTB World, All Rights Reserved
;;; Website: https://jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2007-09-05 - First release
;;; 2009-08-02 - Updated to work in both modelspace and paperspace
;;; 2010-10-29 - Updated to work also on 64-bit AutoCAD
;;; 2018-11-11 - Added command ATC to add the text at the geo center on selected object
;;;              Added command ATM to add the text at the bounding box center on selected objects

;;; Uses TEXTSIZE for the text height

;;; rows starting with one or more semicolons are comments
;;; for the area in square feet leave the below row uncommented or modify as needed
(setq jtbfieldformula ">%).Area \\f \"%pr2%lu2%ct4%qf1 SQ. FT.\">%")

;;; for the area in square meters leave the below row uncommented or modify as needed
;(setq jtbfieldformula ">%).Area \\f \"%lu2%pr1%ps[,m²]%ct8[0.001]\">%")

(defun Get-ObjectIDx64 (obj / util)
  (setq util (vla-get-Utility
               (vla-get-activedocument (vlax-get-acad-object))
             )
  )
  (if (= (type obj) 'ENAME)
    (setq obj (vlax-ename->vla-object obj))
  )
  (if (= (type obj) 'VLA-OBJECT)
    (if (> (vl-string-search "x64" (getvar "platform")) 0)
      (vlax-invoke-method
        util
        "GetObjectIdString"
        obj
        :vlax-False
      )
      (rtos (vla-get-objectid obj) 2 0)
    )
  )
)

;;; Select a polyline and where to place the text
(defun c:AT (/ entObject entObjectID InsertionPoint ad)
  (vl-load-com)
  (setq entObject      (vlax-ename->vla-object (car (entsel)))
        entObjectID    (Get-ObjectIDx64 entObject)
        InsertionPoint (vlax-3D-Point (getpoint "Select point: "))
        ad             (vla-get-ActiveDocument (vlax-get-acad-object))
  )
  (vla-addMText
    (if (= 1 (vla-get-activespace ad))
      (vla-get-modelspace ad)
      (if (= (vla-get-mspace ad) :vlax-true)
        (vla-get-modelspace ad)
        (vla-get-paperspace ad)
      )
    )
    InsertionPoint
    0.0
    (strcat
      "%vla-object (car (setq ent (entsel))))
        entObjectID    (Get-ObjectIDx64 entObject)
        InsertionPoint (vlax-3D-Point
                         (trans (osnap (cadr ent) "_gcen") 1 0)
                       )
        ad             (vla-get-ActiveDocument (vlax-get-acad-object))
  )

  (setq mtextobj
         (vla-addMText
           (if (= 1 (vla-get-activespace ad))
             (vla-get-modelspace ad)
             (if (= (vla-get-mspace ad) :vlax-true)
               (vla-get-modelspace ad)
               (vla-get-paperspace ad)
             )
           )
           InsertionPoint
           0.0
           (strcat
             "%")
                        )
                )
      )
    (progn
      (setq nr 0)
      (setq tot_area 0.0)
      (setq en (ssname ss1 nr))
      (while en
        (setq entObject   (vlax-ename->vla-object en)
              entObjectID (Get-ObjectIDx64 entObject)
              ad          (vla-get-ActiveDocument (vlax-get-acad-object))
        )
        (vla-GetBoundingBox entObject 'minExt 'maxExt)
        (setq minExt (vlax-safearray->list minExt)
              maxExt (vlax-safearray->list maxExt)
        )


        (setq
          InsertionPoint
           (vlax-3D-Point
             (list
               (/ (+ (car minExt) (car maxExt)) 2)
               (/ (+ (cadr minExt) (cadr maxExt)) 2)
               (/ (+ (caddr minExt) (caddr maxExt)) 2)
             )
           )
        )


        (setq mtextobj
               (vla-addMText
                 (if (= 1 (vla-get-activespace ad))
                   (vla-get-modelspace ad)
                   (if (= (vla-get-mspace ad) :vlax-true)
                     (vla-get-modelspace ad)
                     (vla-get-paperspace ad)
                   )
                 )
                 InsertionPoint
                 0.0
                 (strcat
                   "%<\\AcObjProp Object(%<\\_ObjId "
                   entObjectID
                   jtbfieldformula
                 )
               )
        )
        (vla-put-AttachmentPoint mtextobj 5)
        (vla-put-insertionPoint mtextobj InsertionPoint)
        (command "._area" "_O" en)
        (setq tot_area (+ tot_area (getvar "area")))
        (setq nr (1+ nr))
        (setq en (ssname ss1 nr))
      )
      (princ "\nTotal Area = ")
      (princ tot_area)
    )
  )
  (setq ss1 nil)
  (princ)
)

(princ)
