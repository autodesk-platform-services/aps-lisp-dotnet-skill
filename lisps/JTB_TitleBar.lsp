;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2007 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; Tested on AutoCAD 2005 and ADT 2005 up to AutoCAD 2008
;;;
;;; Q: How can I change the title bar to say AutoCAD instead of Architectural Desktop?
;;; A: Download JTB_TitleBar 2005.dvb and you can call it like the example below.
;;;    Change the path as where JTB_TitleBar.dvb is placed.
;;;    To make it fun you might even make it AutoCAD 2003 or whatever you want.

(defun c:JTB_SetTitleBarAutoCAD2005()
  (vl-load-com)
  (setq JTB_TitleBar "AutoCAD 2005")
  (vl-vbarun "C:/Program Files/jtbworld/JTB_TitleBar2005.dvb!JTB_TitleBar")
  (princ)
)

(defun c:JTB_SetTitleBarRevitADT2005()
  (vl-load-com)
  (setq JTB_TitleBar "Revit-ADT 2005")
  (vl-vbarun "C:/Program Files/jtbworld/JTB_TitleBar2005.dvb!JTB_TitleBar")
  (princ)
)

;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2007 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; Tested on AutoCAD 2002 and ADT 3.3
;;;
;;; Q: How can I change the title bar to say AutoCAD instead of Architectural Desktop?
;;; A: Download JTB_TitleBar.dvb and you can call it like the example below.
;;;    Change the path as where JTB_TitleBar.dvb is placed.
;;;    To make it fun you might even make it AutoCAD 2003 or whatever you want.

(defun c:JTB_SetTitleBarAutoCAD2002()
  (vl-load-com)
  (setq JTB_TitleBar "AutoCAD 2002")
  (vl-vbarun "C:/Program Files/jtbworld/JTB_TitleBar.dvb!JTB_TitleBar")
  (princ)
)

(defun c:JTB_SetTitleBarRevitADT2004()
  (vl-load-com)
  (setq JTB_TitleBar "Revit-ADT 2004")
  (vl-vbarun "C:/Program Files/jtbworld/JTB_TitleBar.dvb!JTB_TitleBar")
  (princ)
)
