;;; By Jimmy Bergmark
;;; Copyright (C) 2008 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; Created: 2008-03-31
;;;
;;; Convert Attribute definitions to mtext
;;;

(defun c:AttDefToMText (/ eset1 blkcnt en enlist tag1 ht pnt vl space)
  (setq	eset1  (ssget (list (cons 0 "ATTDEF")))
	blkcnt 0
  )

  (if eset1
    (while (<= blkcnt (- (sslength eset1) 1))
      (setq en	   (ssname eset1 blkcnt)
	    enlist (entget en)
	    ht	   (cdr (assoc 40 enlist))
	    pnt	   (assoc 10 enlist)
	    pnt	   (subst (+ ht (caddr pnt)) (caddr pnt) pnt)
	    space  (cdr (assoc 67 enlist))
      )
      (setq vl (list
		 (cons 0 "MTEXT")
		 (cons 100 "AcDbEntity")
		 (cons 100 "AcDbMText")
		 (assoc 7 enlist)
		 (assoc 8 enlist)
		 pnt
		 (assoc 40 enlist)
		 (cond ((assoc 62 enlist))
		       ((cons 62 256))
		 )
		 (cons 1 (cdr (assoc 2 enlist)))
		 (if (= space nil)
		   (cons 67 0)
		   (cons 67 space)
		 )
	       )
      )
      (entdel en)
      (entmake vl)
      (setq blkcnt (1+ blkcnt))
    )
  )
  (setq eset1 nil)
)
