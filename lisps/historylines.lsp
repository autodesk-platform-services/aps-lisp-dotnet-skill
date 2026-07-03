;;; HISTORYLINES.LSP
;;; Change the number of command history lines.
;;; Saves into profile.
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 1999-09-25 - First release
;;; To be run on AutoCAD 2000

(defun c:PutHistoryLines (/ hl)
  (vl-load-com)
  (if (setq hl 
        (getint
          (strcat "\nNumber of History Lines : ")))
    (if (or ( hl 2048))
      (prompt "\nOnly between 25 and 2048.")
      (vla-put-HistoryLines (vla-get-display (vla-get-preferences (vlax-get-acad-object))) hl)
    )
  )
  (princ)
)

;;; another way to do it by someone else
(defun c:cmdhistlines ( / chl)
  (if (setq chl (getint (strcat "\nNew value for CMDHISTLINES : ")))
    (if (or ( chl 2048))
      (progn
        (prompt "\nRequires and integer between 25 and 2048.")
        (c:cmdhistlines)
      )
      (setenv "CmdHistLines" (itoa chl))
    )
  )
  (princ)
)
