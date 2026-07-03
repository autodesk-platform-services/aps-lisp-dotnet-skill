;;; DisplayProperties.LSP
;;; Miscellaneous commands related to the Display tab on the Options dialog
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2006 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2000-03-29 - First release
;;; Tested on AutoCAD 2000

(vl-load-com)

; Get Model Space Background Color
(defun getMoBgColor()
  (ole_color 
    (vla-get-GraphicsWinModelBackgrndColor
      (vla-get-display (vla-get-preferences (vlax-get-acad-object)))))
)

; Get Layout Space Background Color
(defun getLaBgColor()
  (ole_color 
    (vla-get-GraphicsWinLayoutBackgrndColor
      (vla-get-display (vla-get-preferences (vlax-get-acad-object)))))
)

; Put Model Space Background Color
(defun putMoBgColor(bgc)
  (vla-put-GraphicsWinModelBackgrndColor
    (vla-get-display (vla-get-preferences (vlax-get-acad-object)))
    bgc
  )
)

; Put Layout Space Background Color
(defun putLaBgColor(bgc)
  (vla-put-GraphicsWinLayoutBackgrndColor
    (vla-get-display (vla-get-preferences (vlax-get-acad-object)))
    bgc
  )
)

(defun ole_color(olec)
  (vlax-variant-value
    (vlax-variant-change-type olec vlax-vbDouble)
  )
)

; Get the display of the Plot Setup dialog when a new layout is created. 
(defun getLayoutShowPlotSetup()
  (vla-get-LayoutShowPlotSetup
    (vla-get-display (vla-get-preferences (vlax-get-acad-object))))
)

; Put the display of the Plot Setup dialog when a new layout is created. 
(defun putLayoutShowPlotSetup(state)
  (vla-put-LayoutShowPlotSetup
    (vla-get-display (vla-get-preferences (vlax-get-acad-object))) state)
)

; Toggles the display of the Plot Setup dialog when a new layout is created. 
(defun toggleLayoutShowPlotSetup()
  (if (= (getLayoutShowPlotSetup) :vlax-true)
    (putLayoutShowPlotSetup :vlax-false)
    (putLayoutShowPlotSetup :vlax-true)
  )
)
