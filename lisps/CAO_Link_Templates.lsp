(defun c:CreateLT() 
(vl-load-com) 
(setq pDoc (vla-get-ActiveDocument (vlax-get-acad-object)))


;get the DBConnect
(setq pDBObj (vla-GetInterfaceObject (vlax-get-acad-object)  "CAO.dbConnect"))


  (if (null pDBObj)
    (progn 
 (alert "Cannot create CAO Automation server.") 
 (exit))) 


  ;get the linktemplates
  (setq pLTs(vlax-invoke-method pDBObj "GetLinkTemplates" pDoc))


  ;prepare the keydescriptions
  (setq pKeyDescs (vla-GetInterfaceObject (vlax-get-acad-object)  "CAO.KeyDescriptions"))
  (vlax-invoke-method pKeyDescs "ADD" "TAG_NUMBER" 3 nil nil)
  (vlax-invoke-method pKeyDescs "ADD" "Manufacturer" 1 nil nil)
  ;create two link templates
  (vlax-invoke-method pLTs "ADD" "jet_dbsamples" nil nil "COMPUTER" "LTCreatedByVLispCAO" pKeyDescs)
  (vlax-invoke-method pLTs "ADD" "jet_dbsamples" nil nil "COMPUTER" "LTtobeDeleted" pKeyDescs)


  ;sample code to show how to delete the link template
  (vlax-invoke-method pLTs "delete" "LTtobeDeleted")
 )
