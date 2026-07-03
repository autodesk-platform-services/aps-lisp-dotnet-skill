;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; Tested on AutoCAD 2000
;;;
;;; 2 versions of Insert block with attribute with ActiveX
;;; attributes are rotated to specified angle
(vl-load-com)
(defun c:ax-insrot (/      doc    blk_name      ins    x      y
                    z      rt     rot    blk    atts   ent    ent2
                    promptStr     i      default       txt
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
  (initget 1)
  (setq blk_name (getstring T "\nEnter block name: "))
  (initget 1)
  (setq ins (list->variantArray
              (getpoint "\nSpecify insertion point: ")
            )
        x   (getdist "\nEnter X scale factor : ")
        y   (getdist "\nEnter Y scale factor : ")
        z   (getdist "\nEnter Z scale factor : ")
        rt  (getangle "\nSpecify rotation angle : ")
        rot (getangle "\nSpecify rotation angle for attributes : ")
  )
  (if (= x nil)
    (setq x 1)
  )
  (if (= y nil)
    (setq y x)
  )
  (if (= z nil)
    (setq z y)
  )
  (if (= rt nil)
    (setq rt 0)
  )
  (if (= rot nil)
    (setq rot 0)
  )
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq blk (vla-insertblock
              (vla-get-paperspace doc)
              ins
              blk_name
              x
              y
              z
              rt
            )
  )

  (if (and
        (= (vla-get-hasattributes blk) :vlax-true)
        (safearray-value
          (setq atts
                 (vlax-variant-value
                   (vla-getattributes blk)
                 )
          )
        )
      )
    (progn
      (vlax-for ent (vla-get-blocks doc)
        (if (= (vla-get-name ent) (vla-get-name blk))
          (vlax-for ent2 ent
            (if (= (vla-get-objectname ent2) "AcDbAttributeDefinition")
              (setq promptStr
                     (cons
                         (list (vla-get-PromptString ent2)
                               (vla-get-TextString ent2)
                               (vla-get-TagString ent2)
                         )
                       promptStr
                     )
              )
            )
          )
        )
      )
      (setq i (1- (length promptStr)))
      (princ "\nEnter attribute values\n")
      (foreach tag (vlax-safearray->list atts)
        (vla-put-TextString
          tag
          (if (= (setq
                   txt (getstring
                         T
                         (strcat (if (= (setq default (car (nth i promptStr))) "")
                                   (setq default (caddr (nth i promptStr)))
                                   default
                                 )
                                 " : "
                         )
                       )
                 )
                 ""
              )
            default
            txt
          )
        )
        (vla-put-Rotation tag rot)
        (setq i (1- i))
      )
    )
  )
  (princ)
)

(defun c:insrot (/ cmdecho attdia insblk ent rt tag atts blk)
  (setq cmdecho (getvar "CMDECHO"))
  (setq attdia (getvar "ATTDIA"))
  (setvar "ATTDIA" 1)
  (setvar "CMDECHO" 1)
  (initdia)
  (command "_.-INSERT" "~")
  (while (eq 1 (logand 1 (getvar "CMDACTIVE")))
    (command pause)
  )
  (setq insblk (entlast))
  (setq ent (cdar (entget insblk)))
  (setq blk (vlax-ename->vla-object ent))
  (if (and
        (= (vla-get-hasattributes blk) :vlax-true)
        (safearray-value
          (setq atts
                 (vlax-variant-value
                   (vla-getattributes blk)
                 )
          )
        )
      )
    (progn
      (setq rt
             (getangle "\nSpecify rotation angle for attributes : ")
      )
      (if (= rt nil)
        (setq rt 0)
      )
      (foreach tag (vlax-safearray->list atts)
        (vla-put-Rotation tag rt)
      )
    )
  )
  (setvar "ATTDIA" attdia)
  (setvar "CMDECHO" cmdecho)
  (princ)
)
