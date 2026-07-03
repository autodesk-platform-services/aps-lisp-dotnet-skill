;;; (deleteAllPageSetupsExcept  );;; (deleteAllPageSetupsExcept (vla-get-activedocument (vlax-get-acad-object)) 
	'("PageSetupName1" "PageSetupName2"))(defun deleteAllPageSetupsExcept (doc names)  (vlax-for pc (vla-get-plotconfigurations doc)    (if (not (member (vla-get-name pc) names))      (vla-delete pc)
    )
  )
)

; get paper size on current tab
(defun papersize (/ psn scale)
  (setq
    psn	(member	'(100 . "AcDbPlotSettings")
		(dictsearch
		  (cdr (assoc -1 (dictsearch (namedobjdict) "ACAD_LAYOUT")))
		  (getvar "ctab")
		)
	)
  )
  (if (= (caadr psn) 1) ; Page Setup Name exist
    (progn (setq scale (if (= 0 (cdr (assoc 72 psn)))
			 25.4
			 1.0
		       )
	   )
	   (strcat (rtos (/ (cdr (assoc 44 psn)) scale) 2 2)
		   " x "
		   (rtos (/ (cdr (assoc 45 psn)) scale) 2 2)
	   )
    )
  )
)

;;; PageSetup.LSP
;;; Miscellaneous routines related to Page Setup
;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2011 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com
;;; 2000-04-05 - First release
;;; 2011-02-10 - Second release
;;; Tested on AutoCAD 2000 and AutoCAD 2011
(vl-load-com)
;;; (listPageSetups )
;;; (listPageSetups (vla-get-activedocument (vlax-get-acad-object)))
(defun listPageSetups (doc / pc)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (princ (strcat (vla-get-name pc) "\n"))
  )
  (princ)
)

;;; (allPageSetups )
;;; (allPageSetups (vla-get-activedocument (vlax-get-acad-object)))
(defun allPageSetups (doc / aps pc)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (setq aps (cons (vla-get-name pc) aps))
  )
  (reverse aps)
)

;;; (allPageSetupsAndModelType )
;;; (allPageSetupsAndModelType (vla-get-activedocument (vlax-get-acad-object)))
(defun allPageSetupsAndModelType (doc / aps pc)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (setq aps (cons (cons (vla-get-name pc)
			  (if (= (vla-get-ModelType pc) :vlax-true)
			    "Model"
			    "Layout"
			  )
		    )
		    aps
	      )
    )
  )
  (reverse aps)
)

;;; (allPageSetupsOfModelType )
;;; (allPageSetupsOfModelType (vla-get-activedocument (vlax-get-acad-object)))
(defun allPageSetupsOfModelType (doc / aps)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (if (= (vla-get-ModelType pc) :vlax-true)
      (setq aps (cons (vla-get-name pc) aps))
    )
  )
  (vl-sort aps ')
;;; (allPageSetupsOfLayoutType (vla-get-activedocument (vlax-get-acad-object)))
(defun allPageSetupsOfLayoutType (doc / aps)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (if (= (vla-get-ModelType pc) :vlax-false)
      (setq aps (cons (vla-get-name pc) aps))
    )
  )
  (vl-sort aps ')
;;; (deleteAllPageSetups (vla-get-activedocument (vlax-get-acad-object)))
(defun deleteAllPageSetups (doc)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (vla-delete pc)
  )
)

;;; (deletePageSetup  )
;;; (deletePageSetup (vla-get-activedocument (vlax-get-acad-object)) "PageSetupName")
(defun deletePageSetup (doc name)
  (vlax-for pc (vla-get-plotconfigurations doc)
    (if (= (strcase (vla-get-name pc)) (strcase name))
      (vla-delete pc)
    )
  )
)

;;; add a new page setup name to current layout-type based on current plot configuration
;;; (addPageSetup  )
;;; (addPageSetup (vla-get-activedocument (vlax-get-acad-object)) "PageSetupName")
(defun addPageSetup (doc name / space pc lay)
  (deletePageSetup doc name)
  (if (= (getvar "ctab") "Model")
    (setq space :vlax-true
          lay (vla-get-Layout (vla-get-ModelSpace
                (vla-get-activedocument (vlax-get-acad-object)))))
    (setq space :vlax-false
          lay (vla-get-ActiveLayout (vla-get-activedocument
                (vlax-get-acad-object))))
  )
  (setq pc (vla-add
             (vla-get-plotconfigurations doc)
             name
             space))
  (vla-CopyFrom pc lay)
  (vla-put-name pc name)
)

;;; (getPageSetupName "Model")
;;; (getPageSetupName "Layout1")
;;; (getPageSetupName (getvar "ctab"))
;;; return value: PageSetupName or nil if Page Setup Name doesn't exist
(defun getPageSetupName (layout / laydict psn)
  (setq dn (cdr (assoc -1 (dictsearch (namedobjdict) "ACAD_LAYOUT"))))
  (setq laydict (dictsearch dn layout))
  (setq psn (member '(100 . "AcDbPlotSettings") laydict))
  (if (= (caadr psn) 1)			; Page Setup Name exist
    (setq psn (cdadr psn))
  )
)

;;; (getAllPageSetupName )
;;; (getAllPageSetupName (vla-get-activedocument (vlax-get-acad-object)))
;;; Example return: (("Model" . "PageSetupName") ("Layout1" . "PPA") ("Layout2"))
;;;                 Layout2 has no page setup name
(defun getAllPageSetupName (doc / layoutitem lst)
  (foreach layoutitem (layout-tab-list doc)
    (setq lst (cons (cons layoutitem (getPageSetupName layoutitem)) lst))
  )
  (reverse lst)
)

;; (layout-tab-list  )
;;
;; Returns a list of tne names of all
;; layouts in the specified document,
;; in ascending tab-order.
;; TonyT
;; (layout-tab-list (vla-get-activedocument (vlax-get-acad-object)))
(defun layout-tab-list (doc / layouts)
   (mapcar 'vla-get-name
      (vl-sort
         (vlax-for layout (vla-get-layouts doc)
            (setq layouts (cons layout layouts))
         )
        '(lambda (a b)
            (  )
;;; (setPageSetupName (vla-get-activedocument (vlax-get-acad-object)) "Model" "PageSetupName")
(defun setPageSetupName	(doc layout newpsn / pc layoutitem exist1 exist2)
  (vlax-for layoutitem (vla-get-Layouts doc)
    (if	(= (strcase (vla-get-name layoutitem)) (strcase layout))
      (setq exist1 T)
    )
  )
  (if exist1	; layout exist
    (vlax-for pc (vla-get-plotconfigurations doc)
      (if (and
	    (= (strcase (vla-get-name pc)) (strcase newpsn))
	    (if	(= (strcase layout) "MODEL")
	      (= (vla-get-ModelType pc) :vlax-true)
	      (= (vla-get-ModelType pc) :vlax-false)
	    )
	  )
	(setq exist2 T)
      )
    )
  )
  (if exist2	; page setup name exist for selected model type
    (command "._plot" "_n" layout newpsn "" "" "_y" "_n")
  )
)

;;; Set a named page setup as current on current layout by avoiding command usage
;;; (SetCurrentPageSetup  )
;;; (SetCurrentPageSetup (vla-get-activedocument (vlax-get-acad-object)) "Setup2")
(defun SetCurrentPageSetup (doc pcname / layout PlotConfig)
  (setq	doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq layout (vla-get-activelayout doc))
  (setq PlotConfig (vl-catch-all-apply
		     'vla-item
		     (list
		       (vla-get-PlotConfigurations
			 doc
		       )
		       pcname
		     )
		   )
  )
  (if (not (vl-catch-all-error-p PlotConfig))
    (vla-copyfrom layout PlotConfig)
  )
)
