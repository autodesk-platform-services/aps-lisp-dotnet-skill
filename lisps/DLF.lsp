;;; DLF.LSP
;;;
;;; Delete all layer filters with the DLF command
;;;
;;; By Jimmy Bergmark
;;; Copyright (C) 2004-2008 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2004-05-23 - Added support to delete filters introduced in 2005
;;; 2005-03-14 - Confirmed to work with AutoCAD 2006
;;; 2005-04-19 - Added (vl-load-com)
;;; Written for AutoCAD 2000, 2000i, 2002, 2004, 2005, 2006, 2007, 2008, 2009
;;;

(vl-load-com)

;;; Purge/delete all layer filter or filters
;;; Example: (DeleteLayerFilters)
(defun DeleteLayerFilters ()
(vl-Catch-All-Apply
'(lambda ()
(vla-Remove
(vla-GetExtensionDictionary
(vla-Get-Layers
(vla-Get-ActiveDocument
(vlax-Get-Acad-Object))))
"ACAD_LAYERFILTERS")))
)
;;; Purge/delete all layer filter or filters compatible with 2005 or later
;;; Example: (DeleteLayerFilters2)
(defun DeleteLayerFilters2 ()
(vl-Catch-All-Apply
'(lambda ()
(vla-Remove
(vla-GetExtensionDictionary
(vla-Get-Layers
(vla-Get-ActiveDocument
(vlax-Get-Acad-Object))))
"AcLyDictionary")))
)

(defun c:dlf()
(DeleteLayerFilters)
(DeleteLayerFilters2)
(princ "\nAll layer filters deleted!")
(princ)
)
