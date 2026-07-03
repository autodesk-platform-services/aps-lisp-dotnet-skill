;;;---------------------------------------------------------------------------;
;;;
;;; accdist.lsp
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;; 1999-06-12 - First release
;;; 2000-05-11 - Fixed for AutoCAD 2000
;;; should be working on older versions too.
;;;
;;;---------------------------------------------------------------------------;
;;;  Methods to accumulate distances
;;;  c:accdist - combined
;;;  c:accdist1 - accumulate distances from first point to next point
;;;  c:accdist2 - accumulate distances from first point to second point
;;;---------------------------------------------------------------------------;
(defun c:accdist (/ errexit undox restore *error* p1 p2 sum)
  (defun errexit (s)
    (princ)
    (restore)
  )
  (defun undox ()
    (redraw)
    (setq *error* olderr)
    (princ)
  )
  (setq olderr  *error*
        restore undox
        *error* errexit
  )
  (setq p1  (getpoint "\nSpecify first point: ")
        p2  "First"
        sum 0
  )
  (while (and p1 p2)
    (if (= p2 "First")
      (progn
        (initget 32)
        (setq p2 (getpoint "\nSpecify next point: " p1))
      )
      (progn
        (initget 32 "First")
        (setq p2 (getpoint "\nSpecify next point or [First]: " p1))
      )
    )
    (cond
      ((not p2))
      ((= p2 "First")
       (setq p1 (getpoint "\nSpecify first point: "))
      )
      (t
       (grdraw p1 p2 -1 1)
       (setq sum (+ sum (distance p1 p2))
             p1  p2
       )
      )
    )
  )
  (princ "\nAccumulated distance = ")
  (princ sum)
  (restore)
)
(defun c:accdist1 (/ p1 p2 sum)
  (setq sum 0)
  (setq p1 (getpoint "\nSpecify first point: "))
  (while (and p1
              (not (initget 32))
              (setq p2 (getpoint "\nSpecify next point: " p1))
         )
    (grdraw p1 p2 -1 1)
    (setq sum (+ sum (distance p1 p2)))
    (setq p1 p2)
  )
  (redraw)
  (princ "\nAccumulated distance = ")
  (princ sum)
  (princ)
)
(defun c:accdist2 (/ p1 p2 sum)
  (setq sum 0)
  (while
    (and (setq p1 (getpoint "\nSpecify first point: "))
         (not (initget 32))
         (setq p2 (getpoint "\nSpecify second point: " p1))
    )
     (setq sum (+ sum (distance p1 p2)))
  )
  (princ "\nAccumulated distance = ")
  (princ sum)
  (princ)
)
