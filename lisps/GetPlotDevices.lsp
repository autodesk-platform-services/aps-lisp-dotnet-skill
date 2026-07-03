;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com

; (setq ad (vla-get-activedocument (vlax-get-acad-object)))
(vl-load-com)
(defun GetCanonicalMediaNames (ad)
  (vla-RefreshPlotDeviceInfo
    (vla-get-activelayout ad))
  (vlax-safearray->list
    (vlax-variant-value
      (vla-GetCanonicalMediaNames
        (vla-item (vla-get-layouts ad) "Model"))))
)

(defun GetLocaleMediaNames (ad / mn mnl)
  (setq la (vla-item (vla-get-layouts ad) "Model"))
  (foreach mn (GetCanonicalMediaNames ad)
    (setq mnl (cons (vla-GetLocaleMediaName la mn) mnl))
  )
  (reverse mnl)
)

(defun GetPlotDevices (ad)
  (vla-RefreshPlotDeviceInfo
    (vla-get-activelayout ad))
  (vlax-safearray->list
    (vlax-variant-value
      (vla-getplotdevicenames
        (vla-item (vla-get-layouts ad) "Model"))))
)

; Plot Device in active Layout
(defun GetActivePlotDevice (ad)
  (vla-get-ConfigName
    (vla-get-ActiveLayout ad))
)

(defun GetPlotStyleTableNames (ad)
  (vla-RefreshPlotDeviceInfo
    (vla-get-activelayout ad))
  (vlax-safearray->list
    (vlax-variant-value
      (vla-getplotstyletablenames
        (vla-item (vla-get-layouts ad) "Model"))))
)

(defun ListAllMediaNames(ad / al cn pd apmn)
  (setq al (vla-get-activelayout  ad))
  (setq cn (vla-get-configname al))
  (foreach pd (GetPlotDevices ad)
    (if (/= pd "None")
      (progn
        (vla-put-configname al pd)
        (setq apmn (cons pd apmn))
        (setq apmn (cons (GetCanonicalMediaNames ad) apmn))
      )
    )
  )
  (if (/= cn "None") (vla-put-configname al cn))
  (reverse apmn)
)

; (ListAllLocalMediaNames (vla-get-activedocument (vlax-get-acad-object)))
(defun ListAllLocalMediaNames(ad / al cn pd apmn)
  (setq al (vla-get-activelayout ad))
  (setq cn (vla-get-configname al))
  (foreach pd (GetPlotDevices ad)
    (if (/= pd "None")
      (progn
        (vla-put-configname al pd)
        (setq apmn (cons pd apmn))
        (setq apmn (cons (GetLocaleMediaNames ad) apmn))
      )
    )
  )
  (if (/= cn "None") (vla-put-configname al cn))
  (reverse apmn)
)

; (GetCanonicalMediaNamesOfConfigname ad "Acrobat PDFWriter")
(defun GetCanonicalMediaNamesOfConfigname(ad cn / oldcn al cmn)
  (setq al (vla-get-ActiveLayout ad))
  (setq oldcn (vla-get-configname al))
  (vla-put-configname al cn)
  (vla-RefreshPlotDeviceInfo al)
  (setq cmn (GetCanonicalMediaNames ad))
  (if (/= oldcn "None") (vla-put-configname al oldcn))
  cmn
)

; (GetLocalMediaNamesOfConfigname ad "Acrobat PDFWriter")
(defun GetLocalMediaNamesOfConfigname(ad cn / oldcn al cmn)
  (setq al (vla-get-ActiveLayout ad))
  (setq oldcn (vla-get-configname al))
  (vla-put-configname al cn)
  (vla-RefreshPlotDeviceInfo al)
  (setq cmn (GetLocaleMediaNames ad))
  (if (/= oldcn "None") (vla-put-configname al oldcn))
  cmn
)
