;;; ProjectPaths.LSP
;;; Among other things it can save the paths 
;;;  to a file that can be imported on another PC.
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; Tested on AutoCAD 2000, 2006

(vl-load-com)

(defun ReadProject-Settings (cprof)
  (vl-registry-descendents
    (strcat
      "HKEY_CURRENT_USER\\"
      (vlax-product-key)
      "\\Profiles\\"
      cprof
      "\\Project Settings"
    )
  )
)

(defun ReadRefSearchPath (cprof ProjSet)
  (vl-registry-read
    (strcat
      "HKEY_CURRENT_USER\\"
      (vlax-product-key)
      "\\Profiles\\"
      cprof
      "\\Project Settings\\"
      ProjSet
    )
    "RefSearchPath"
  )
)

;;; Ex: (AllProjPath (getvar "CPROFILE"))
(defun AllProjPath (cprof / lst ProjSet)
  (foreach ProjSet (ReadProject-Settings cprof)
    (setq lst (cons (cons ProjSet (ReadRefSearchPath cprof ProjSet)) lst))
  )
)

;;; Ex: (WriteRefSearchPath (getvar "CPROFILE") "Project1" "c:\temp;c:\project")
(defun WriteRefSearchPath (cprof ProjSet path)
  (vl-registry-write
    (strcat
      "HKEY_CURRENT_USER\\"
      (vlax-product-key)
      "\\Profiles\\"
      cprof
      "\\Project Settings\\"
      ProjSet
    )
    "RefSearchPath"
    path
  )
)

;;; Deletes all Project paths
(defun DeleteRefSearchPath (cprof)
  (foreach ProjSet (ReadProject-Settings cprof)
    (vl-registry-delete
      (strcat
        "HKEY_CURRENT_USER\\"
        (vlax-product-key)
        "\\Profiles\\"
        cprof
        "\\Project Settings\\"
        ProjSet
      )
    )
  )
)

;;; Ex: (WriteAllProjPath (getvar "CPROFILE") (list (cons "Project1" "C:\\") (cons "Project2" "D:\\")))
;;; Deletes all old Paths first
(defun WriteAllProjPath (cprof lst / ProjSet)
  (DeleteRefSearchPath cprof)
  (foreach ProjSet lst
    (WriteRefSearchPath cprof (car ProjSet) (cdr ProjSet))
  )
)

;;; Ex: (Print-AllProjPaths (getvar "CPROFILE"))
(defun Print-AllProjPaths (cprof / ProjSet)
  (princ "Project Files Search Path:\n")
  (foreach ProjSet (ReadProject-Settings cprof)
    (princ ProjSet)
    (princ " = ")
    (princ (ReadRefSearchPath cprof ProjSet))
    (terpri)
  )
  (princ)
)

;;; Change "r:\\paths.txt" to a location on the server
;;; (getProjectPaths "r:\\paths.txt")
(defun getProjectPaths (fn / cprof paths f)
  (setq cprof (getvar "CPROFILE"))
  (setq paths (AllProjPath cprof))
  (setq f (open fn "w"))
  (foreach ProjSet (ReadProject-Settings cprof)
    (write-line ProjSet f)
    (write-line (ReadRefSearchPath cprof ProjSet) f)
  )  
  (close f)
)

;;; Change "r:\\paths.txt" to a location on the server
;;; (putProjectPaths "r:\\paths.txt")
(defun putProjectPaths (fn / cprof  line1 line2 paths f)
  (setq cprof (getvar "CPROFILE"))
  (setq f (open fn "r"))
  (while (and (setq line1 (read-line f)) (setq line2 (read-line f)))
    (setq paths (cons (cons line1 line2) paths))
  )
  (close f)
  (WriteAllProjPath cprof paths)
)
