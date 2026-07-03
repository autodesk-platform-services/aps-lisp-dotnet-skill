;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2016 JTB World Inc., All Rights Reserved
;;; Website: http://jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; Updated: 2016-05-26
;;; To support dynamic blocks use vla-get-effectivename instead of vla-get-name
;;;

;;; (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

;;; Erases all blocks named "revtext2"
;;; (ax:EraseBlock doc "revtext2")
(defun ax:EraseBlock (doc bn / layout i)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (vla-Delete i) 
      )
    )
  )
)

;;; Test if block named "revtext2" exist
;;; (ax:ExistBlock doc "revtext2")
(defun ax:ExistBlock (doc bn / layout i exist)
  (setq exist nil)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (setq exist T)
      )
    )
  )
  exist
)

;;; Rename block from "revtext" to "revtext1"
;;; (ax:RenameBlock doc "revtext" "revtext1")
(defun ax:RenameBlock (doc bn nn / layout i)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (vla-put-name i nn)
      )
    )
  )
)

;;; a list of all block names
;;; return example ("*D5" "A$C263E5435" "b2" "b1")
(defun ax:blocks (/ b bn tl)
  (vlax-for b (vla-get-blocks
                (vla-get-ActiveDocument (vlax-get-acad-object))
              )
    (if (= (vla-get-islayout b) :vlax-false)
      (setq tl (cons (vla-get-name b) tl))
    )
  )
  (reverse tl)
)

;;; a list of all xref names
;;; return example ("xref1" "x2")
(defun ax:xrefs (/ b bn tl)
  (vlax-for b (vla-get-blocks
                (vla-get-ActiveDocument (vlax-get-acad-object))
              )
    (if (= (vla-get-isxref b) :vlax-true)
      (setq tl (cons (vla-get-name b) tl))
    )
  )
  (reverse tl)
)

;;; Returns a list with references to a given block
;;; (blockrefs )
;;; example: (blockrefs "b1")
;;; return: ( )
;;; tip: if return is nil it's not inserted
(defun blockrefs (bn / lst ed)
  (if (setq ed (tblobjname "block" bn))
    (setq
      lst (entget
            (cdr (assoc 330 (entget ed)))
          )
    )
  )
  (apply
    'append
    (mapcar '(lambda (x)
               (list (cdr x))
             )
            (cdr (reverse (cdr (member (assoc 102 lst) lst))))
    )
  )
)

;;; Returns a list containing every reference to a given block
;;; Arguments: a string identifying the block to search for
(defun listblockrefs (blkName / lst)
  (setq	lst (entget
	      (cdr (assoc 330 (entget (tblobjname "block" blkName))))
	    )
  )
  (apply
    'append
    (mapcar '(lambda (x)
	       (if (entget (cdr x))
		 (list (cdr x))
	       )
	     )
	    (cdr (reverse (cdr (member (assoc 102 lst) lst))))
    )
  )
)

;;; Returns a list containing the entity names
;;; of block definitions that reference a given block
;;; Arguments: a string identifying the block to search for
(defun ax:GetParentBlocks (blkName / doc)
  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (apply
    'append
    (mapcar '(lambda (x)
	       (if (= :vlax-false
		      (vla-get-IsLayout
			(vla-ObjectIdToObject
			  doc
			  (vla-get-OwnerId (vlax-ename->vla-object x))
			)
		      )
		   )
		 (list x)
	       )
	     )
	    (listblockrefs blkName)
    )
  )
)

;;; Deletes the specified subentity from its block definition
;;; Arguments: the entity name of an item within a block reference
;;; Returns: the remaining item count of the block definition
;;; The drawing must be regenerated for the change to become visible
(defun ax:DeleteObjectFromBlock	(ent / doc blk)
  (setq	doc (vla-get-ActiveDocument (vlax-get-acad-object))
	ent (vlax-ename->vla-object ent)
	blk (vla-ObjectIdToObject doc (vla-get-OwnerID ent))
  )
  (vla-Delete ent)
  (vla-get-Count blk)
)

;;; Adds the specified item to a given block definition
;;; Arguments: the entity name of a block reference
;;;            a selection set containing the objects to add
;;; Returns: nil
;;; The drawing must be regenerated for the change to become visible
(defun ax:AddObjectsToBlock (blk ss / doc blkref blkdef inspt refpt)
  (setq	doc	(vla-get-ActiveDocument (vlax-get-acad-object))
	blkref	(vlax-ename->vla-object blk)
	blkdef	(vla-Item (vla-get-Blocks doc) (vla-get-Name blkref))
	inspt	(vlax-variant-value (vla-get-InsertionPoint blkref))
	ssarray	(selectionset->array ss)
	refpt	(vlax-3d-point '(0 0 0))
  )
  (foreach ent (vlax-safearray->list ssarray)
    (vla-Move ent inspt refpt)
  )
  (vla-CopyObjects doc ssarray blkdef)
  (foreach ent (vlax-safearray->list ssarray)
    (vla-Delete ent)
  )
  (princ)
)

;;; Utility routine to convert a selection set to an ActiveX array
(defun selectionset->array (ss / c r)
  (vl-load-com)
  (setq c -1)
  (repeat (sslength ss)
    (setq r (cons (ssname ss (setq c (1+ c))) r))
  )
  (setq r (reverse r))
  (vlax-safearray-fill
    (vlax-make-safearray
      vlax-vbObject
      (cons 0 (1- (length r)))
    )
    (mapcar 'vlax-ename->vla-object r)
  )
)

;;; (ax:GetTagTextString doc "sheet-text" "client-drw")
(defun ax:GetTagTextString (doc bn tagname / layout i atts tag str)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
                (setq atts
                       (vlax-variant-value
                         (vla-getattributes i)
                       )
                )
              )
            )    
          (foreach tag (vlax-safearray->list atts)
            (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
              (setq str (vla-get-TextString tag))
            )
          )
        )
      )
    )
  )
  str
)

;;; (ax:FindBlockTagValue (vla-get-activedocument
;;; (vlax-get-acad-object)) "blockname" "tagname" "tagvalue")
(defun ax:FindBlockTagValue
       (doc bn tagname value / layout i atts tag sset c)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
                (setq atts
                       (vlax-variant-value
                         (vla-getattributes i)
                       )
                )
              )
            )
          (progn
            (foreach tag (vlax-safearray->list atts)
              (if (and
                    (= (strcase tagname)
                       (strcase (vla-get-TagString tag))
                    )
                    (= value (vla-get-TextString tag))
                  )
                (progn
                  (if (not sset)
                    (setq sset (ssadd (vlax-vla-object->ename i)))
                    (ssadd (vlax-vla-object->ename i) sset)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  (sssetfirst nil sset)
)

;;; list of all "REV-NO" in block "revtext1" in order of y-coordinate, bottom to up
;;; (ax:GetManyTags "revtext1" "REV-NO")
(defun ax:GetManyTags (bn tag / ax lst)
  (foreach x (ax:ListBlockIns doc bn)
    (setq lst (cons (ax:GetTagTextStringByRef (cadddr x) tag) lst))
  )
  (reverse lst)
)

;;; list of all "REV-NO" in block "revtext2" in order of y-coordinate, bottom to up
;;; (ax:SetManyTags "revtext2" "revtext1" "REV-NO" "REV-NO")
(defun ax:SetManyTags (bn-to bn-from tag-to tag-from / ax lst i)
  (setq lst (ax:GetManyTags bn-from tag-from))
  (setq i 0)
  (foreach x (ax:ListBlockIns doc bn-to)
    (ax:PutTagTextStringByRef (cadddr x) tag-to (nth i lst))
    (setq i (1+ i))
  )
)

;;; (ax:GetTagTextStringByRef # "REV-NO")
(defun ax:GetTagTextStringByRef (br tagname / atts tag str)
  (if (and
        (= (vla-get-hasattributes br) :vlax-true)
        (safearray-value
          (setq atts
                 (vlax-variant-value
                   (vla-getattributes br)
                 )
          )
        )
      )
    (foreach tag (vlax-safearray->list atts)
      (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
        (setq str (vla-get-TextString tag))
      )
    )
  )
  str
)

;;; (ax:PutTagTextString doc "sheet-text" "client-drw" "new value")
(defun ax:PutTagTextString (doc bn tagname textstring / layout i atts tag)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
                (setq atts
                       (vlax-variant-value
                         (vla-getattributes i)
                       )
                )
              )
            )    
          (foreach tag (vlax-safearray->list atts)
            (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
              (vla-put-TextString tag textstring)
            )
          )
          (vla-update i)
        )
      )
    )
  )
)

;;; (ax:PutTagTextStringByRef #
;;; "REV-NO" "new value")
(defun ax:PutTagTextStringByRef (br tagname textstring / atts tag)
  (if (and
        (= (vla-get-hasattributes br) :vlax-true)
        (safearray-value
          (setq atts
                 (vlax-variant-value
                   (vla-getattributes br)
                 )
          )
        )
      )
    (foreach tag (vlax-safearray->list atts)
      (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
        (vla-put-TextString tag textstring)
      )
    )
    (vla-update br)
  )
)

;;; (ax:ChangeTagHeight    )
;;; (ax:ChangeTagHeight doc "sheet-text" "client-drw" 0.97)
(defun ax:ChangeTagHeight (doc bn tagname tagheight / layout i atts tag)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
              (setq atts
                     (vlax-variant-value
                       (vla-getattributes i)
                     )
              )
            )
             )    
          (foreach tag (vlax-safearray->list atts)
            (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
              (vla-put-height tag tagheight)
            )
          )
          (vla-update i)
        )
      )
    )
  )
)

;;; List the insertion point and reference of a block in active layout
;;; sort them by y-value
;;; (ax:ListBlockIns doc "revtext1")
;;; return value example:
;;; ((341.385 29.2937 0.0 #)
;;;  (341.385 34.2937 0.0 #)
;;;  (341.385 39.2937 0.0 #))
(defun ax:ListBlockIns (doc bn / layout i pl)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (setq pl
               (cons
                 (append (safearray-value
                           (vlax-variant-value (vla-get-InsertionPoint i))
                         )
                         (list i)
                 )
                 pl
               )
        )
      )
    )
  )
  ; sort by y-value
  (vl-sort pl 
             (function (lambda (e1 e2) 
                         (variantArray (ptsList / arraySpace sArray)
    (setq arraySpace
      (vlax-make-safearray
        vlax-vbdouble
        (cons 0 (- (length ptsList) 1))
      )
    )
    (setq sArray (vlax-safearray-fill arraySpace ptsList))
    (vlax-make-variant sArray)
  )
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
              (setq atts
                     (vlax-variant-value
                       (vla-getattributes i)
                     )
              )
            )
             )    
          (foreach tag (vlax-safearray->list atts)
            (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
              (vla-put-InsertionPoint tag (list->variantArray ins))
            )
          )
          (vla-update i)
        )
      )
    )
  )
)

;;; Changes attributes on all block references matching 
;;; (ChangeAttributes (list  '( . ) ...))
;;; (ChangeAttributes (list "testblock" '("TESTTAG2" . "item1") '("NEWTAG" . "tagvalue")))
(defun ChangeAttributes (lst / sset item atts ename i)
  (setq i 0)
  (setq sset (ssget "X" (list '(0 . "INSERT") (cons 2 (car lst)))))
  (if sset
    (repeat (sslength sset)
      (setq ename (ssname sset i))
      (setq i (+ 1 i))
      (if (safearray-value
            (setq atts
                   (vlax-variant-value
                     (vla-getattributes (vlax-ename->vla-object ename))
                   )
            )
          )
        (progn
          (foreach item (cdr lst)
            (mapcar
              '(lambda (x)
                 (if
                   (= (strcase (car item))
                      (strcase (vla-get-tagstring x))
                   )
                    (vla-put-textstring x (cdr item))
                 )
               )
              (vlax-safearray->list atts)
            )
          )
          (vla-update (vlax-ename->vla-object ename))
        )
      )
    )
  )
  (setq sset nil)
)

;;; (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
;;; (ax:ChangeTagWidth    )
;;; (ax:ChangeTagWidth doc "panel1" "drw-no" 0.97)
(defun ax:ChangeTagWidth (doc bn tagname tagwidth / layout i atts tag)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (and
            (= (vla-get-objectname i) "AcDbBlockReference")
            (= (strcase (vla-get-name i)) (strcase bn))
          )
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
              (setq atts
                     (vlax-variant-value
                       (vla-getattributes i)
                     )
              )
            )
             )    
          (foreach tag (vlax-safearray->list atts)
            (if (= (strcase tagname) (strcase (vla-get-tagstring tag)))
              (vla-put-scalefactor tag tagwidth)
            )
          )
          (vla-update i)
        )
      )
    )
  )
);;; Updates the attribute tag with everywhere in the drawing
;;; (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
;;; (ax:ChangeTagWidthAll  )
;;; (ax:ChangeTagWidthAll doc 0.5)
(defun ax:ChangeTagWidthAll (doc tagwidth / layout i atts tag)
  (vlax-for layout (vla-get-layouts doc)
    (vlax-for i (vla-get-block layout)
      (if (= (vla-get-objectname i) "AcDbBlockReference")
        (if (and
              (= (vla-get-hasattributes i) :vlax-true)
              (safearray-value
              (setq atts
                     (vlax-variant-value
                       (vla-getattributes i)
                     )
              )
            )
             )    
          (foreach tag (vlax-safearray->list atts)
            (vla-put-scalefactor tag tagwidth)
          )
          (vla-update i)
        )
      )
    )
  )
)
