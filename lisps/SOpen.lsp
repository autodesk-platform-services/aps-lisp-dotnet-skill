;;; SOPEN.LSP
;;; Open command that works for all cases
;;; Works for SDI=0 or SDI=1 

;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 1999-09-12 - First release
;;; 2002-05-14 - Bug fixed
;;; Written for AutoCAD 2000+
;;; Ex: (sopen "c:\\drawing1.dwg")
;;; Note that QAFLAGS might not be restored to 0 so you might want to add (setvar "qaflags" 0) to acaddoc.lsp or any other startup lisp.

;;; opens and activates a file as Read-Only
(defun openRO (fna)
  (vla-activate (vla-open (vla-get-documents (vlax-get-acad-object)) fna :VLAX-TRUE))
)

(defun sopen (fna / n)
  (if (= 0 (getvar "SDI"))
    (vla-activate (vla-open (vla-get-documents (vlax-get-acad-object)) fna))
    (progn
      (if (not (equal 2 (logand 2 (getvar "qaflags")))) 
        (setvar "qaflags" (+ (getvar "qaflags") 2))
      )
      (if (not (equal 4 (logand 4 (getvar "qaflags")))) 
       (setvar "qaflags" (+ (getvar "qaflags") 4))
      )
      (command "_.open")
      (if (not (equal 0 (getvar "dbmod")))
        (command "_y")
      )
      (command fna)  
      (setq n 0)
      (while (and (< n 4)
                  (wcmatch (getvar "cmdnames") "*OPEN*")
             )
          (T
            (command "")
          )
        (setq n (+ n 1))
      )
      (setvar "qaflags" 0)
    )
  )
)
