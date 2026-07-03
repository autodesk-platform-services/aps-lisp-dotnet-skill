;;; BlockToXref.LSP
;;; Select one or many blocks in a drawing and change them to xrefs
;;; The xrefs needs to be existing before running this command

;;; By Jimmy Bergmark
;;; Copyright (C) 1997-2014 JTB World, All Rights Reserved
;;; Website: www.jtbworld.com
;;; E-mail: info@jtbworld.com

;;; 2000-04-03 - First release
;;; Supports nested blocks, multiple tabs
;;; 2014-12-15 - Updated to work with newer versions of AutoCAD
;;; Tested on AutoCAD 2000 and 2015

(defun c:btx () (c:BlockToXref))
(defun c:BlockToXref (/            errexit      undox
                      olderr       restore      errexitA2k
                      ss ss1 e1 ix path
                      bsl bn bnl bl bt not_ok repl oldvport oldregenmode
                      typ ed layer color ltype ang ins tab oldtab
                     )
  (defun errexit (s)
    (princ "\nError:  ")
    (princ s)
    (restore)
  )

  (defun undox ()
    (setq ss1 nil)
    (setq ss2 nil)
    (setvar "ctab" oldtab)
    (if (> oldcvport 1) (command "._mspace") (command "._pspace"))
    (setvar "cvport" oldcvport)
    (setvar "regenmode" oldregenmode)
    (command "._undo" "_E")
    (setvar "cmdecho" oldcmdecho)
    (setq *error* olderr)
    (princ)
  )

  (setq olderr  *error*
        restore undox
        *error* errexit
  )
  (setq oldcmdecho (getvar "cmdecho"))
  (setq oldtab (getvar "ctab"))
  (setq oldcvport (getvar "cvport"))
  (setq oldregenmode (getvar "regenmode"))
  (setvar "cmdecho" 0)
  (setvar "regenmode" 0)
  (command "._UNDO" "_BE")
  (setq A2k (>= (substr (getvar "ACADVER") 1 2) "15"))
  (if (and A2k (/= (setq ss1 (ssget '((0 . "INSERT")))) nil))
    (progn
      (vl-load-com)
      (setq ix 0)
      (setq bsl nil) ; block selection list
      (setq bnl nil) ; unique block name list
      (repeat (sslength ss1)
        (setq e1 (ssname ss1 ix))
        (setq bn (cdr (assoc 2 (entget e1)))) ; block name
        (setq bl (tblsearch "block" bn)) ; block list bn
        (setq bt (cdr (assoc 70 bl))) ; block type
        (if (and (/= (logand bt 4) 4) (not (member bn bnl))) ; no xrefs and no duplicates
           (setq bnl (cons bn bnl))
        )
        (setq ix (1+ ix))
      ); end repeat

      (foreach bn bnl
        (setq ss1 (ssget "X" (list (cons 0 "INSERT") (cons 2 bn))))
        (setq ix 0)
        (repeat (sslength ss1)
          (setq e1 (ssname ss1 ix))
          (setq bsl (cons (entget e1) bsl))
          (setq ix (1+ ix))
        )
      ); end repeat

      (foreach bn bnl
        (setq not_ok T)
        (while not_ok
          (setq path (getfiled "Match the block to a file"
                               (if (not path) (strcat (getvar "dwgprefix") bn) (strcat (vl-filename-directory path) "\\" bn))
                               "dwg" 0))
          (if path
            (if (= (strcase (vl-filename-base  path)) (strcase bn))
              (setq not_ok nil)
              (progn
                (initget 0 "Yes No")
                (setq repl (getkword "\nAssign a different name? [Yes/No] : "))
                (if (not repl) (setq repl "Yes"))
                (if (= "Yes" repl)
                  (setq not_ok nil)
                  (setq not_ok T)
                )
              )        
            )
          )
          (if (not not_ok)
            (progn
              (setq ss (ssget "X" (list (cons 0 "INSERT") (cons 2 bn))))
              (setq ix 0)
              (repeat (sslength ss)
                (setq ed (ssname ss ix))
                (setq tab (cdr (assoc 410 (entget ed))))
                (setvar "ctab" tab)
                (entdel ed)
                (setq ix (1+ ix))
              )
              (repeat 10
                (vl-cmdf "._purge" "_b" "*" "N")
              )
              (initget 0 "Overlay Attach")
              (setq repl (getkword "\nEnter an option [Overlay/Attach] : "))
              (if (not repl) (setq repl "Attach"))
              (if (= "Attach" repl) (setq typ "_A") (setq typ "_O"))
              (setq ix 0)
              (repeat (length bsl)
                (setq ed (nth ix bsl))
                (if (= bn (cdr (assoc 2 ed)))
                  (progn
                    (setq layer (cdr (assoc 8 ed)))
                    (setq color (cdr (assoc 62 ed)))
                    (if (not color) (setq color "_ByLayer"))
                    (setq ltype (cdr (assoc 6 ed)))
                    (if (not ltype) (setq ltype "_ByLayer"))
                    (setq ang (/ (* 180.0 (cdr (assoc 50 ed))) pi))
                    (setq ins (cdr (assoc 10 ed)))
                    (setq tab (cdr (assoc 410 ed)))
                    (setvar "ctab" tab)
                    (if (/= tab "Model") (command "._pspace"))
                    (vl-cmdf "._xref" typ path "_X" (cdr (assoc 41 ed)) "_Y" (cdr (assoc 42 ed)) "_Z" (cdr (assoc 43 ed)) ins ang)
                    (vl-cmdf "._change" "_L" "" "_P" "_C" color "_LA" layer "_LT" ltype "")
                  )
                )
                (setq ix (1+ ix))
              )
            )
          )
          (if (= path nil) (setq not_ok nil))
        )
      )
    ); end progn
  ); end if
  (setq ss1 nil)
  (restore)
)
