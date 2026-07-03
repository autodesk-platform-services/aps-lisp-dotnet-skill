;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com

;;; Midpoint of 2 points
(defun c:mpt (/ pt1 pt2)
  (if (and
        (= (getvar "cmdactive") 1)
        (setq pt1 (getpoint "\nFirst point: "))
        (setq pt2 (getpoint pt1 "\nSecond point: "))
    )
    (command 
      "_non" 
      (list
        (/ (+ (car pt1) (car pt2)) 2)
        (/ (+ (cadr pt1) (cadr pt2)) 2)
        (/ (+ (caddr pt1) (caddr pt2)) 2)
      )
    )
  )
  (princ)
)

;;; 1/3:rd point of 2 points
(defun c:3pt (/ pt1 pt2)
  (if (and
        (= (getvar "cmdactive") 1)
        (setq pt1 (getpoint "\nFirst point: "))
        (setq pt2 (getpoint pt1 "\nSecond point: "))
    )
    (command
      "_non"
      (list
        (+ (/ (- (car pt2) (car pt1)) 3) (car pt1))
        (+ (/ (- (cadr pt2) (cadr pt1)) 3) (cadr pt1))
        (+ (/ (- (caddr pt2) (caddr pt1)) 3) (caddr pt1))
      )
    )
  )
  (princ)
)

;;; 1/4:th point of 2 points
(defun c:4pt (/ pt1 pt2)
  (if (and
        (= (getvar "cmdactive") 1)
        (setq pt1 (getpoint "\nFirst point: "))
        (setq pt2 (getpoint pt1 "\nSecond point: "))
    )
    (command
      "_non"
      (list
        (+ (/ (- (car pt2) (car pt1)) 4) (car pt1))
        (+ (/ (- (cadr pt2) (cadr pt1)) 4) (cadr pt1))
        (+ (/ (- (caddr pt2) (caddr pt1)) 4) (caddr pt1))
      )
    )
  )
  (princ)
)

;;; Midpoint of 3 points
(defun c:mpt3 (/ pt1 pt2 pt3)
  (if (and
        (= (getvar "cmdactive") 1)
        (setq pt1 (getpoint "\nFirst point: "))
        (setq pt2 (getpoint pt1 "\nSecond point: "))
        (setq pt3 (getpoint pt2 "\nThird point: "))
    )
    (command
      "_non"
      (list
        (/ (+ (car pt1) (car pt2) (car pt3)) 3)
        (/ (+ (cadr pt1) (cadr pt2) (cadr pt3)) 3)
        (/ (+ (caddr pt1) (caddr pt2) (caddr pt3)) 3)
      )
    )
  )
  (princ)
)
