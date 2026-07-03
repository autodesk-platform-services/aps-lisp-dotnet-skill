;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;;
;;;  PlotDevicesFunctions.lsp
;;;
;;; 2003-01-09 More functions added
;;; 2006-07-30 Make it possible to add this lisp into your acaddoc.lsp
;;; 2006-12-15 Corrected a minor bug
;;;

(vl-load-com)

(defun ActLay ()
  (vla-get-ActiveLayout
    (vla-get-activedocument
      (vlax-get-acad-object)
    )
  )
)

  ; Return the Plotter configuration name
(defun GetActivePlotDevice ()
  (vla-get-ConfigName
    (ActLay)
  )
)

  ; Return the Plot style table name
(defun GetActiveStyleSheet ()
  (vla-get-StyleSheet
    (ActLay)
  )
)

  ; Force the Plotter configuration to something
(defun PutActivePlotDevice (PlotDeviceName)
  (vla-put-ConfigName
    (ActLay)
    PlotDeviceName
  )
)

  ; Force the Plot style table to something
(defun PutActiveStyleSheet (StyleSheetName)
  (vla-put-StyleSheet
    (ActLay)
    StyleSheetName
  )
)

  ; Return a list of all Plotter configurations
(defun PlotDeviceNamesList ()
  (vla-RefreshPlotDeviceInfo (ActLay))
  (vlax-safearray->list
    (vlax-variant-value
      (vla-GetPlotDeviceNames
        (ActLay)
      )
    )
  )
)

  ; Return a list of all Plot style tables
(defun PlotStyleTableNamesList ()
  (vla-RefreshPlotDeviceInfo (ActLay))
  (vlax-safearray->list
    (vlax-variant-value
      (vla-GetPlotStyleTableNames
        (ActLay)
      )
    )
  )
)

  ; If the saved Plotter configuration doesn't exist set it to None
(defun PutActivePlotDeviceToNoneIfNotExist ()
  (if (not (member (GetActivePlotDevice) (PlotDeviceNamesList)))
    (PutActivePlotDevice "None")
  )
)

  ; If the saved Plot style table doesn't exist set it to None
(defun PutActiveStyleSheetToNoneIfNotExist ()
  (if (not
        (member (GetActiveStyleSheet) (PlotStyleTableNamesList))
      )
    (PutActiveStyleSheet "")
  )
)

  ; Change the Plotter configuration "CompanyStandard.pc3" to your need
(defun PutActivePlotDeviceToCompanyStandardIfNotExist ()
  (if (not (member (GetActivePlotDevice) (PlotDeviceNamesList)))
    (PutActivePlotDevice "CompanyStandard.pc3")
  )
)

  ; Change the Plot style table "CompanyStandard-A3-BW.ctb" to your need
(defun PutActiveStyleSheetToCompanyStandardIfNotExist ()
  (if (not
        (member (GetActiveStyleSheet) (PlotStyleTableNamesList))
      )
    (PutActiveStyleSheet "CompanyStandard-A3-BW.ctb")
  )
)

  ; Change the Plotter configuration to the default one set in the options
  ; if the active plot device does not exist
(defun PutActivePlotDeviceToDefaultIfNotExistOrNone ()
  (if (or (not (member (GetActivePlotDevice) (PlotDeviceNamesList)))
          (= (GetActivePlotDevice) "None")
      )
    (if (= (vla-get-UseLastPlotSettings
             (vla-get-output
               (vla-get-preferences (vlax-get-acad-object))
             )
           )
           :vlax-true
        )
      (PutActivePlotDevice
        (getenv "General\\MRUConfig")
      )
      (PutActivePlotDevice
        (vla-get-DefaultOutputDevice
          (vla-get-output
            (vla-get-preferences (vlax-get-acad-object))
          )
        )
      )
    )
  )
)

  ; Change the Plot style table to the default one set in the options
  ; if the active Plot style table does not exist
(defun PutActiveStyleSheetToDefaultIfNotExistOrNone ()
  (if (or (not
            (member (GetActiveStyleSheet) (PlotStyleTableNamesList))
          )
          (= (GetActiveStyleSheet) "")
      )
    (PutActiveStyleSheet
      (vla-get-DefaultPlotStyleTable
        (vla-get-output
          (vla-get-preferences (vlax-get-acad-object))
        )
      )
    )
  )
)

  ; Customize this as you want
  ; Either force the Plot Device and/or the Style Sheet to something
  ; or only if the saved setting doesn't exist.

  ; If the Plot Device (printer, plotter or PC3 file) saved in the drawing
  ; and that will be used when printing does not exist or is set to None
  ; set it instead to your default plotter/printer
(PutActivePlotDeviceToDefaultIfNotExistOrNone)

  ; If the Plot Style Table saved in the drawing
  ; and that will be used when printing does not exist or is set to None
  ; set it instead to your default plot style table
(PutActiveStyleSheetToDefaultIfNotExistOrNone)

  ; These below can be used if you want them set to None if they don't exists
  ;(PutActivePlotDeviceToNoneIfNotExist)
  ;(PutActiveStyleSheetToNoneIfNotExist)

  ; If you want to enforce another company standard you can
  ; activate and change in these functions
  ;(PutActivePlotDeviceToCompanyStandardIfNotExist)
  ;(PutActiveStyleSheetToCompanyStandardIfNotExist)

(princ)
