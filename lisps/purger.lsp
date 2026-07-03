;;; PURGER.LSP
;;;
;;; Various purge functions with no command line echo
;;; 
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2018 JTB World, All Rights Reserved
;;; Website: https://jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2000-02-12 - First release
;;; 2003-01-09 - More added
;;; 2004-05-23 - Added support to delete filters in 2005
;;; 2018-03-21 - Bug fix
;;; Written for AutoCAD 2000 and newer
;;;
;;; Purge named block
;;; Example: (ax:purge-block (vla-get-activedocument (vlax-get-acad-object)) "testblock")
;;; Argument: doc {document}
;;;           name {a block name}
;;; Return values: T if successful, nil if not successful
(defun ax:purge-block (doc name)
  (if (vl-catch-all-error-p
        (vl-catch-all-apply
          'vla-delete
          (list (vl-catch-all-apply
                  'vla-item
                  (list (vla-get-blocks doc) name)
                )
          )
        )
      )
    nil ; name cannot be purged or doesn't exist
    T ; name purged
  )
)

;;; Purge named layer
;;; Example: (ax:purge-layer (vla-get-activedocument (vlax-get-acad-object)) "testlayer")
;;; Argument: doc {document}
;;;           name {a layer name}
;;; Return values: T if successful, nil if not successful
(defun ax:purge-layer (doc name)
  (if (vl-catch-all-error-p
        (vl-catch-all-apply
          'vla-delete
          (list (vl-catch-all-apply
                  'vla-item
                  (list (vla-get-layers doc) name)
                )
          )
        )
      )
    nil ; name cannot be purged or doesn't exist
    T ; name purged
  )
)

;;; Purge all layers
;;; Example: (ax:purge-all-layers (vla-get-activedocument (vlax-get-acad-object)))
;;; Argument: doc {document}
(defun ax:purge-all-layers (doc)
  (vlax-for item (vla-get-layers doc)
    (ax:purge-layer doc (vla-get-name item))
  )
)

;;; Purge all layers except those in list
;;; Example: (ax:purge-layers (vla-get-activedocument (vlax-get-acad-object)) '("DIM" "LAYER1"))
;;; Argument: doc {document}
;;;           name {a layer name list}
(defun ax:purge-layers (doc except)
  (vlax-for item (vla-get-layers doc)
    (setq ln (vla-get-name item))
    (if (not (member (strcase ln) except))
      (ax:purge-layer doc ln)
    )
  )
)

;;; Purge all with no echo to command window
;;; Example: (ax:purge-no-echo (vla-get-activedocument (vlax-get-acad-object)))
;;; Argument: doc {document}
(defun ax:purge-no-echo (doc)

;;; Returns a list of keynames from the specified dictionary
(defun getkeys (dictName / tmp)
  (if (setq tmp (dictsearch (namedobjdict) dictName))
    (massoc 3 tmp)
  )
)

;;; Retrieves the entity name of the specified dictionary
(defun getdictname (dictName)
  (if (setq tmp (dictsearch (namedobjdict) dictName))
    (cdr (assoc -1 tmp))
  )
)
  
;;; Utility function to get multiple group code CDRs
(defun massoc (key alist / x nlist)
  (foreach x alist
    (if (eq key (car x))
      (setq nlist (cons (cdr x) nlist))
    )
  )
  (reverse nlist)
)
  
  (vlax-for item (vla-get-blocks doc)
    (vl-catch-all-apply 'vla-delete (list item))
  )
  (vlax-for item (vla-get-dimstyles doc)
    (vl-catch-all-apply 'vla-delete (list item))
  )
  (vlax-for item (vla-get-linetypes doc)
    (vl-catch-all-apply 'vla-delete (list item))
  )
  (vlax-for item (vla-get-plotconfigurations doc)
    (vl-catch-all-apply 'vla-delete (list item))
  )
  ; textstyles
  (vlax-for item (vla-get-textstyles doc)
    (if (= (cdr (assoc 70 (entget (vlax-vla-object->ename item)))) 0)
      (vl-catch-all-apply 'vla-delete (list item))
    )
  )
  ; shapes
  (vlax-for item (vla-get-textstyles doc)
    (if (= (cdr (assoc 70 (entget (vlax-vla-object->ename item)))) 1)
      (vl-catch-all-apply 'vla-delete (list item))
    )
  )
  (setq li (getkeys "ACAD_MLINESTYLE"))
  (setq len (length li))
  ; one style has to be left
  (foreach na (cdr li)
    (delrecord "ACAD_MLINESTYLE" na)
  )
  (setq li (getkeys "ACAD_MLINESTYLE"))
  (setq len (length li))
  (if (> len 1)
    (delrecord "ACAD_MLINESTYLE" (car li))
  )
  (vlax-for item (vla-get-layers doc)
    (vl-catch-all-apply 'vla-delete 'item)
  )
  nil
)

;;; Purge/delete all layer filter or filters
;;; Example: (DeleteLayerFilters)
(defun DeleteLayerFilters ()
  (vl-Catch-All-Apply
    '(lambda ()
       (vla-Remove
	 (vla-GetExtensionDictionary
	   (vla-Get-Layers
	     (vla-Get-ActiveDocument (vlax-Get-Acad-Object))
	   )
	 )
	 "ACAD_LAYERFILTERS"
       )
     )
  )
  (princ)
)

(defun delrecord (dictName key)
  (dictremove (getdictname dictName) key)
)

;;; Retrieves the entity name of the specified dictionary
(defun getdictname (dictName)
  (if (setq tmp (dictsearch (namedobjdict) dictName))
    (cdr (assoc -1 tmp))
  )
)

(princ)

;;; Purge/delete all layer filter or filters compatible with 2005 or later
;;; Example: (DeleteLayerFilters2)
(defun DeleteLayerFilters2 ()
  (vl-Catch-All-Apply
    '(lambda ()
       (vla-Remove
	 (vla-GetExtensionDictionary
	   (vla-Get-Layers
	     (vla-Get-ActiveDocument (vlax-Get-Acad-Object))
	   )
	 )
	 "AcLyDictionary"
       )
     )
  )
  (princ)
)

;;; How many layer states are there in my drawing?
;;; This command will show the number of them.
;;; Command: count-layer-states
;;; Example of output
;;; Layer states found: 15191
(defun c:count-layer-states (/ ed cnt lso)
  (setq ed (vla-GetExtensionDictionary
             (vla-Get-Layers
               (vla-Get-ActiveDocument
                 (vlax-Get-Acad-Object)
			   )
             )
           )
  )
  (setq cnt 0)
  (if (> (vla-get-count ed) 0)
    (vlax-for lso (vla-item ed "ACAD_LAYERSTATES")
	  (setq cnt (1+ cnt))
    )
  )
  (princ "\nLayer states found: ")
  (princ cnt)
  (princ)
)

;;; Purge/delete all layer states
;;; Example: (DeleteLayerStates)
(defun DeleteLayerStates  ()
 (vl-Catch-All-Apply
  '(lambda ()
    (vla-Remove (vla-GetExtensionDictionary
                 (vla-Get-Layers 
                  (vla-Get-ActiveDocument
                   (vlax-Get-Acad-Object))))
                "ACAD_LAYERSTATES")))
 (princ)
)

;;; Purge/delete all Express Tool layer states
;;; Example: (LmanKill)
(defun LmanKill (/ lyr ent cnt)
  (setq cnt 0)
  (while (setq lyr (tblnext "layer" (not lyr)))
    (setq ent (entget (tblobjname "layer" (cdr (assoc 2 lyr)))'("RAK")))
    (if (and ent (assoc -3 ent))
      (progn
        (setq ent (subst '(-3 ("RAK")) (assoc -3 ent) ent))
        (entmod ent)
        (setq cnt (1+ cnt))
      )
    )
  )
 (princ)
)

;;; (deleteAllPageSetups)
(defun deleteAllPageSetups (/ pc)
  (vlax-for pc (vla-get-plotconfigurations (vla-get-activedocument (vlax-get-acad-object)))
    (vla-delete pc)
  )
)

(defun PurgeAnonymGroups (/ grpList index grp)
  (setq grpList (dictsearch (namedobjdict) "ACAD_GROUP"))
  (setq index 1)
  (while (setq grp (nth index grplist))
    (if	(= (car grp) 3)
      (progn
	(if (= (chr 42) (substr (cdr grp) 1 1))
	  (entdel (cdr (nth (+ index 1) grplist)))
	)
      )
    )
    (setq index (+ 1 index))
  )
  (princ)
)

(defun PurgeAllGroups (/ grpList index grp)
  (setq grpList (dictsearch (namedobjdict) "ACAD_GROUP"))
  (setq index 1)
  (while (setq grp (nth index grplist))
    (if	(= (car grp) 3)
      (entdel (cdr (nth (+ index 1) grplist)))
    )
    (setq index (+ 1 index))
  )
  (princ)
)

(defun DelACAD_VBA ()
  (dictremove (namedobjdict) "ACAD_VBA")
  (princ)
)

; Purges all RegApp or RegApps.

(defun PurgeAPPID (/ appid)
  (vl-load-com)
  (vlax-for appid (vla-get-registeredapplications
		    (vla-get-activedocument
		      (vlax-get-acad-object)
		    )
		  )
    (vl-catch-all-apply 'vla-delete (list appid))
  )
  (princ)
)
