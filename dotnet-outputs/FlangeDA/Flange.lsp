;;; This routine will draw a flange in various elevations.
;;; Also user defined hole patterns.
;;; Peter Best  October 1998

;;; This function will save & reset environment ;
(defun set_env ()
  (setq	oldblip	   (getvar "blipmode")
	oldecho	   (getvar "cmdecho")
	oldosmode  (getvar "osmode")
	oldlayer   (getvar "clayer")
	dscale     (getvar "dimscale")
	appname	   "Flange.lsp"
	olderror   *error*
	*error*	   err_hand
	select	   "sabs"
	typ1	   "1"
	typ2	   "1"
	typ3	   "0"
	typ4	   "0"
	offset	   "1"
	pipeod	   "1"
	size	   "9"
	ftang	   "0"
	view	   "front"
	ddthick	   "0"
	flag	   0
	fod	   220
	pcd	   180
	bqt	   8
	bdi	   18
	pipe	   114.3
	thk	   12
	textheight 3.5
  ) ;_ end of setq
  (setvar "blipmode" 0)
  (setvar "cmdecho" 0)
) ;_ end of defun

;;; Function will convert degrees to radians ;
(defun Degrees->Radians	(numberOfDegrees)
  (* pi (/ numberOfDegrees 180.0))
) ;_ end of defun

;;; This function will load the dialog box.
(defun DialogBox (/ DCL_ID)
  (if (findfile "flange.dcl")		; Looks for dialog box file
    (progn
      (setq DCL_ID (load_dialog "flange")) ; Load dialog box
      (if (not (new_dialog "flange" DCL_ID))
	(exit)
      ) ;_ end of if
      (setq w (dimx_tile "im")
	    h (dimy_tile "im")
      ) ;_ end of setq
      (start_image "im")		; Draws logo
      (fill_image 0 0 w h 164)
					;
      (vector_image 1 20 20 2 4)
      (vector_image 1 2 20 2 4)
      (vector_image 20 2 20 20 4)
      (vector_image 20 20 1 20 4)
					;
      (vector_image 1 20 1 2 4)
      (vector_image 6 11 6 4 4)
      (vector_image 6 4 9 4 4)
      (vector_image 9 4 10 5 4)
      (vector_image 10 5 10 6 4)
      (vector_image 10 6 9 7 4)
      (vector_image 9 7 6 7 4)
					;
      (vector_image 13 18 13 11 4)
      (vector_image 13 11 16 11 4)
      (vector_image 16 11 17 12 4)
      (vector_image 17 12 17 13 4)
      (vector_image 17 13 16 14 4)
      (vector_image 13 14 17 14 4)
      (vector_image 17 14 18 15 4)
      (vector_image 18 15 18 17 4)
      (vector_image 18 17 17 18 4)
      (vector_image 17 18 13 18 4)
      (end_image)
      ;; Set up buttons
      (action_tile "cancel" "(done_dialog 0) (exit)") ;_ end of action_tile
					; Exit out cleanly
      (action_tile "accept" "(setq flag 1)(done_dialog 1)")
					; Ok button
      (action_tile "notes" "(setq flag 10)(update)(done_dialog 1)")
      (action_tile "size" "(setq size $value)(update)")
      (action_tile "view" "(setq view $value)(update)")
      (action_tile "ftang" "(setq ftang $value)")
      (action_tile "offset" "(setq offset $value)")
      (action_tile "pipeod" "(setq pipeod $value)")
      (action_tile "select" "(setq select $value)(update)")
      (action_tile "ddthick" "(setq ddthick $value)(update)")
      (action_tile "typ1" "(setq typ1 $value)(update)")
      (action_tile "typ2" "(setq typ2 $value)(update)")
      (action_tile "typ3" "(setq typ3 $value)(update)")
      (action_tile "typ4" "(setq typ4 $value)(update)")
      (set_tile "offset" offset)
      (set_tile "pipeod" pipeod)
      (set_tile "ftang" ftang)
      (set_tile "did" (rtos pipe))
      (set_tile "dod" (rtos fod))
      (set_tile "dpcd" (rtos pcd))
      (set_tile "dno" (rtos bqt))
      (set_tile "ddia" (rtos bdi))
      (set_tile "dthick" (rtos thk))
      (mode_tile "ddthick" 1)
      (mode_tile "textt" 1)
      (mode_tile "offset" 0)
      (mode_tile "pipeod" 0)
      (mode_tile "ftang" 0)
      (mode_tile "texta" 0)
      (mode_tile "view" 0)
      (mode_tile "rf" 0)
      (mode_tile "notes" 0)
      (start_dialog)
    ) ;_ end of progn
    (alert "Unable to find Flange.dcl")
  ) ;_ end of if
) ;_ end of defun

;;; This function will update all relevent buttons
;;; and display "Alert" messages.
(defun update ()
  (if (/= select "pat")
    (if	(= view "front")
      (progn
	(mode_tile "view" 0)		; on
	(mode_tile "notes" 0)		; on
	(mode_tile "textt" 1)		; off
	(mode_tile "ddthick" 1)		; off
	(mode_tile "offset" 0)		; on
	(mode_tile "pipeod" 0)		; on
	(mode_tile "ftang" 0)		; on
	(mode_tile "texta" 0)		; on
	(mode_tile "did" 0)
	(mode_tile "dod" 0)
	(mode_tile "dpcd" 0)
	(mode_tile "dno" 0)
	(mode_tile "ddia" 0)
	(mode_tile "dthick" 0)
      ) ;_ end of progn
      (progn
	(mode_tile "view" 0)		; on
	(mode_tile "notes" 0)		; on
	(mode_tile "textt" 0)		; on
	(mode_tile "ddthick" 0)		; on
	(mode_tile "did" 0)
	(mode_tile "dod" 0)
	(mode_tile "dpcd" 0)
	(mode_tile "dno" 0)
	(mode_tile "ddia" 0)
	(mode_tile "dthick" 0)
	(mode_tile "offset" 1)		; off
	(mode_tile "pipeod" 1)		; off
	(mode_tile "ftang" 1)		; off
	(mode_tile "texta" 1)		; off
      ) ;_ end of progn
    ) ;_ end of if
    (progn
      (mode_tile "view" 1)		; off
      (mode_tile "notes" 1)		; off
      (mode_tile "textt" 1)		; off
      (mode_tile "ddthick" 1)		; off
      (mode_tile "pipeod" 1)		; off
      (mode_tile "did" 1)
      (mode_tile "dod" 1)
      (mode_tile "dpcd" 1)
      (mode_tile "dno" 1)
      (mode_tile "ddia" 1)
      (mode_tile "dthick" 1)
      (mode_tile "offset" 0)		; on
      (mode_tile "ftang" 0)		; on
      (mode_tile "texta" 0)		; on
      (input_pattern)
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "sabs") (= thick "nonstd"))
    (progn (set_tile "ddthick" "0")
	   (setq ddthick "0")
	   (setq thick "std")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "bs") (= thick "nonstd"))
    (progn (set_tile "ddthick" "0")
	   (setq ddthick "0")
	   (setq thick "std")
    ) ;_ end of progn
  ) ;_ end of if
  (if (= select "ansi")
    (mode_tile "rf" 1)
  ) ;_ end of if
  (if (= select "as")
    (mode_tile "rf" 1)
  ) ;_ end of if
  (if (and (= select "as") (= thick "nonstd"))
    (progn (set_tile "ddthick" "0")
	   (setq ddthick "0")
	   (setq thick "std")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= size "8") (= select "sabs"))
    (progn (alert "90NB is not available for SABS 1123")
	   (set_tile "size" "9")
	   (setq size "9")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= size "8") (= select "bs"))
    (progn (alert "90NB is not available for BS 4504")
	   (set_tile "size" "9")
	   (setq size "9")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= size "20") (= select "bs"))
    (progn (alert "550NB is not available for BS 4504")
	   (set_tile "size" "9")
	   (setq size "9")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= size "16") (/= select "as"))
    (progn (set_tile "size" "9")
	   (setq size "9")
	   (set_tile "pipeod" "1")
	   (setq pipeod "1")
	   (alert "375NB is not available for this flange")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= size "16")
	   (= select "as")
	   (= view "front")
	   (= pipeod "1")
      ) ;_ end of and
    (progn (mode_tile "pipeod" 1)
	   (set_tile "pipeod" "0")
	   (setq pipeod "0")
	   (alert "Pipe OD is not available for this flange")
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "ansi") (= view "rf"))
    (progn
      (set_tile "view" "front")
      (setq view "front")
      (mode_tile "pipeod" 0)
      (mode_tile "ftang" 0)
      (mode_tile "texta" 0)
      (mode_tile "offset" 0)
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "as") (= view "rf"))
    (progn
      (set_tile "view" "front")
      (setq view "front")
      (mode_tile "pipeod" 0)
      (mode_tile "ftang" 0)
      (mode_tile "texta" 0)
      (mode_tile "offset" 0)
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= ddthick "0") (= select "ansi") (= view "ff"))
    (progn
      (alert
	"Standard flat face thickness are not available\n         in this program for ANSI B16.5"
      ) ;_ end of alert
      (set_tile "ddthick" "1")
      (setq ddthick "1"
	    thick   "nonstd"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (= size "0")
    (setq pipe 21.3)
  ) ;_ end of if
  (if (= size "1")
    (setq pipe 26.9)
  ) ;_ end of if
  (if (= size "2")
    (setq pipe 33.7)
  ) ;_ end of if
  (if (= size "3")
    (setq pipe 42.4)
  ) ;_ end of if
  (if (= size "4")
    (setq pipe 48.3)
  ) ;_ end of if
  (if (= size "5")
    (setq pipe 60.3)
  ) ;_ end of if
  (if (= size "6")
    (setq pipe 76.1)
  ) ;_ end of if
  (if (= size "7")
    (setq pipe 88.9)
  ) ;_ end of if
  (if (= size "8")
    (setq pipe 101.6)
  ) ;_ end of if
  (if (= size "9")
    (setq pipe 114.3)
  ) ;_ end of if
  (if (= size "10")
    (setq pipe 139.7)
  ) ;_ end of if
  (if (= size "11")
    (setq pipe 168.3)
  ) ;_ end of if
  (if (= size "12")
    (setq pipe 219.1)
  ) ;_ end of if
  (if (= size "13")
    (setq pipe 273.0)
  ) ;_ end of if
  (if (= size "14")
    (setq pipe 323.9)
  ) ;_ end of if
  (if (= size "15")
    (setq pipe 355.6)
  ) ;_ end of if
  (if (= size "17")
    (setq pipe 406.4)
  ) ;_ end of if
  (if (= size "18")
    (setq pipe 457.2)
  ) ;_ end of if
  (if (= size "19")
    (setq pipe 508.0)
  ) ;_ end of if
  (if (= size "20")
    (setq pipe 559.0)
  ) ;_ end of if
  (if (= size "21")
    (setq pipe 609.6)
  ) ;_ end of if
  (setq	flsize '("15NB"	    "20NB"     "25NB"	  "32NB"     "40NB"
		 "50NB"	    "65NB"     "80NB"	  "90NB"     "100NB"
		 "125NB"    "150NB"    "200NB"	  "250NB"    "300NB"
		 "350NB"    "375NB"    "400NB"	  "450NB"    "500NB"
		 "550NB"    "600NB"
		)
  ) ;_ end of setq
  (setq sizex (nth (atoi size) flsize))
  (if (and (= select "sabs") (= typ1 "0"))
    (progn
      (setq sizex (strcat sizex "SABS600")
	    line2 "DRILLED TO SABS 1123/600"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "sabs") (= typ1 "1"))
    (progn
      (setq sizex (strcat sizex "SABS1000")
	    line2 "DRILLED TO SABS 1123/1000"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "sabs") (= typ1 "2"))
    (progn
      (setq sizex (strcat sizex "SABS1600")
	    line2 "DRILLED TO SABS 1123/1600"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "sabs") (= typ1 "3"))
    (progn
      (setq sizex (strcat sizex "SABS2500")
	    line2 "DRILLED TO SABS 1123/2500"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "bs") (= typ2 "0"))
    (progn
      (setq sizex (strcat sizex "BS6")
	    line2 "DRILLED TO BS 4504 TABLE 6"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "bs") (= typ2 "1"))
    (progn
      (setq sizex (strcat sizex "BS10")
	    line2 "DRILLED TO BS 4504 TABLE 10"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "bs") (= typ2 "2"))
    (progn
      (setq sizex (strcat sizex "BS16")
	    line2 "DRILLED TO BS 4504 TABLE 16"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "bs") (= typ2 "3"))
    (progn
      (setq sizex (strcat sizex "BS25")
	    line2 "DRILLED TO BS 4504 TABLE 25"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "ansi") (= typ3 "0"))
    (progn
      (setq sizex (strcat sizex "#150")
	    line2 "DRILLED TO ANSI B16.5 #150"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "ansi") (= typ3 "1"))
    (progn
      (setq sizex (strcat sizex "#300")
	    line2 "DRILLED TO ANSI B16.5 #300"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "ansi") (= typ3 "2"))
    (progn
      (setq sizex (strcat sizex "#400")
	    line2 "DRILLED TO ANSI B16.5 #400"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "ansi") (= typ3 "3"))
    (progn
      (setq sizex (strcat sizex "#600")
	    line2 "DRILLED TO ANSI B16.5 #600"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "as") (= typ4 "0"))
    (progn
      (setq sizex (strcat sizex "ASD")
	    line2 "DRILLED TO AS 2129 TABLE D"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "as") (= typ4 "1"))
    (progn
      (setq sizxe (strcat sizex "ASE")
	    line2 "DRILLED TO AS 2129 TABLE E"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "as") (= typ4 "2"))
    (progn
      (setq sizex (strcat sizex "ASF")
	    line2 "DRILLED TO AS 2129 TABLE F"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (if (and (= select "as") (= typ4 "3"))
    (progn
      (setq sizex (strcat sizex "ASH")
	    line2 "DRILLED TO AS 2129 TABLE H"
      ) ;_ end of setq
    ) ;_ end of progn
  ) ;_ end of if
  (grab)
  (mapcar 'set '(fod pcd bqt bdi thk rdi hgt) dlist)
  (set_tile "dod" (rtos fod))
  (set_tile "did" (rtos pipe))
  (set_tile "dpcd" (rtos pcd))
  (set_tile "dno" (rtos bqt))
  (set_tile "ddia" (rtos bdi))
  (setq	selectthk '("std"  "6"	  "8"	 "10"	"12"   "14"   "16"
		    "18"   "20"	  "22"	 "24"	"26"   "28"   "30"
		    "32"   "34"	  "36"	 "38"	"40"   "45"   "50"
		    "55"   "60"
		   )
  ) ;_ end of setq
  (setq selectthk (nth (atoi ddthick) selectthk))
  (if (/= selectthk "std")
    (progn
      (setq thkx (atof selectthk))
      (set_tile "dthick" selectthk)
    ) ;_ end of progn
    (progn
      (if (and (= view "front") (= select "ansi"))
	(set_tile "dthick" "*")
	(progn
	  (setq thkx thk)
	  (set_tile "dthick" (rtos thk))
	) ;_ end of progn
      ) ;_ end of if
    ) ;_ end of progn
  ) ;_ end of if

) ;_ end of defun


;;; This function decides what to draw
(defun check ()
  (if (and (= view "front") (= ftang "0") (/= select "pat"))
    (draw_front)
  ) ;_ end of if
  (if (and (= view "front") (/= ftang "0") (/= select "pat"))
    (draw_anglefront)
  ) ;_ end of if
  (if (and (= select "pat") (= ftang "0"))
    (draw_pattern)
  ) ;_ end of if
  (if (and (= select "pat") (/= ftang "0"))
    (draw_angpattern)
  ) ;_ end of if
  (if (= view "ff")
    (draw_flatFlange)
  ) ;_ end of if
  (if (= view "rf")
    (draw_raisedFlange)
  ) ;_ end of if
) ;_ end of defun


;;; This function draw the flange in plan
(defun draw_front (/ pt1 pt2 pt3 dlist ra)
  (setq pick_cen (getpoint "\n Pick centre of flange. "))
  (setvar "osmode" 0)			; switches off object snaps
  (if (= offset "1")			; chooses whether to draw off centre or not
    (setq ra (/ 180 bqt))
    (setq ra 0)
  ) ;_ end of if
  (setq	pt1 (polar pick_cen (Degrees->Radians ra) (/ pcd 2))
					; point of first hole
	pt2 (polar pt1 (Degrees->Radians (+ 180 ra)) bdi)
					; first point of hole c/line
	pt3 (polar pt2 (Degrees->Radians ra) (* bdi 2))
					; second point of hole c/line
	bqt (fix bqt)
  ) ;_ end of setq
  (if (= pipeod "1")
    (command "circle" pick_cen (/ pipe 2))
  )					; decides if to draws pipe
  (command "circle"
	   pick_cen
	   (/ fod 2)
	   "circle"
	   pt1
	   (/ bdi 2)
	   "array"
	   "L"
	   ""
	   "P"
	   pick_cen
	   bqt
	   "360"
	   "Y"
	   "layer"
	   "m"
	   "centre"
	   "c"
	   "green"
	   ""
	   "l"
	   "center"
	   ""
	   ""
	   "circle"
	   pick_cen
	   (/ pcd 2)
	   "line"
	   pt2
	   pt3
	   ""
	   "array"
	   "L"
	   ""
	   "P"
	   pick_cen
	   bqt
	   "360"
	   "Y"
  ) ;_ end of command
) ;_ end of defun

;;; This function will draw an
;;; angled front flange.
(defun draw_anglefront ()
  (setq	pick_cen (getpoint "\n Pick centre of flange. ")
	halfpcd	 (/ pcd 2)
	minuspcd (- halfpcd bdi)
	pluspcd	 (+ halfpcd bdi)
	trighole (* halfpcd (cos (Degrees->Radians (atof ftang))))
	trigcl1	 (* minuspcd (cos (Degrees->Radians (atof ftang))))
	trigcl2	 (* pluspcd (cos (Degrees->Radians (atof ftang))))
	yvalue	 (cadr pick_cen)
	count	 0
	pt1	 (polar pick_cen (Degrees->Radians 180) (/ fod 2))
					; points for O.D. ellipse
	pt2	 (polar pick_cen (Degrees->Radians 0) (/ fod 2))
	pt3	 (polar	pick_cen
			(Degrees->Radians 90)
			(* (/ fod 2) (sin (Degrees->Radians (- 90 (atof ftang)))))
		 ) ;_ end of polar
	od1	 (polar pick_cen (Degrees->Radians 180) (/ pipe 2))
					; points for O.D. ellipse
	od2	 (polar pick_cen (Degrees->Radians 0) (/ pipe 2))
	od3	 (polar
		   pick_cen
		   (Degrees->Radians 90)
		   (* (/ pipe 2) (sin (Degrees->Radians (- 90 (atof ftang)))))
		 ) ;_ end of polar
	pt4	 (polar pick_cen (Degrees->Radians 180) halfpcd)
					; points for pcd ellipse
	pt5	 (polar pick_cen (Degrees->Radians 0) halfpcd)
	pt6	 (polar	pick_cen
			(Degrees->Radians 90)
			(* halfpcd (sin (Degrees->Radians (- 90 (atof ftang)))))
		 ) ;_ end of polar
  ) ;_ end of setq
  (setvar "osmode" 0)			; switches off object snaps
  (mark)
  (if (= pipeod "1")
    (command "ellipse" od1 od2 od3)
  )					; decides if to draws pipe
  (command "ellipse"	     pt1      pt2      pt3	"layer"
	   "m"	    "centre" "c"      "green"  ""	"l"
	   "center" ""	     ""	      "ellipse"		pt4
	   pt5	    pt6
	  ) ;_ end of command
   (if (= offset "1")			; chooses whether to draw off centre or not
    (setq ra (Degrees->Radians (/ 180 bqt)))
    (setq ra 0)
  ) ;_ end of if
  (while (< count bqt)			; p1 = centre of hole
    (setq p1  (list (car (polar pick_cen ra halfpcd))
		    (+ yvalue
		       (* (sin ra) trighole) ;_ end of *
		    ) ;_ end of +
	      ) ;_ end of list
	  ra  (+ ra (Degrees->Radians (/ 360 bqt)))
	  el1 (polar p1 (Degrees->Radians 180) (/ bdi 2))
					; works out hole ellipse points
	  el2 (polar p1 (Degrees->Radians 0) (/ bdi 2))
	  el3 (polar
		p1
		(Degrees->Radians 90)
		(* (/ bdi 2) (sin (Degrees->Radians (- 90 (atof ftang)))))
	      ) ;_ end of polar
    ) ;_ end of setq
    (setq la (list (car (polar pick_cen ra minuspcd))
					;centre line point
		   (+ yvalue (* (sin ra) trigcl1))
	     ) ;_ end of list
	  lb (list (car (polar pick_cen ra pluspcd)) ;centre line point
		   (+ yvalue (* (sin ra) trigcl2))
	     ) ;_ end of list
    ) ;_ end of setq
    (command "layer" "m"     "centre"	     "c"     "green" ""
	     "l"     "center"	     ""	     ""	     "line"  la
	     lb	     ""
	    ) ;_ end of command
    (setvar "clayer" oldlayer)
    (command "ellipse"
	     el1
	     el2
	     el3
    ) ;_ end of command

    (setq count (1+ count))
  ) ;_ end of while
  (setvar "osmode" oldosmode)
  (prompt "\nRotation Angle : ")
  (command "ROTATE" (catch) "" pick_cen pause)
) ;_ end of defun

;;; This function will draw user
;;; defined hole pattern
(defun input_pattern ()
  (if (not (new_dialog "pattern" dcl_id))
    (exit)
  ) ;_ end of if
  (action_tile
    "cancel"
    "(done_dialog 0) (setq user nil)"
  ) ;_ end of action_tile
  (action_tile "accept" "(done_dialog 1) (setq user T) ")
					; (action_tile "cancel" "(done_dialog 0) (exit)")
  (action_tile "ddpcd" "(setq ddpcd $value)")
  (action_tile "num" "(setq num $value)")
  (action_tile "holedia" "(setq holedia $value)")
  (start_dialog)
  (if user
    (if	(or ddpcd)
      (if (/= ddpcd "")
	(if (or num)
	  (if (/= num "")
	    (if	(or holedia)
	      (if (/= holedia "")
		(if
		  (>= (* (atof num) (atof holedia)) (* (atof ddpcd) pi))
		   (alert "    Too many holes??")
		) ;_ end of if
		(alert "           No hole dia")
	      ) ;_ end of if
	      (alert "           No hole dia")
	    ) ;_ end of if
	    (alert "    No. of holes not given")
	  ) ;_ end of if
	  (alert "    No. of holes not given")
	) ;_ end of if
	(alert "             No pcd")
      ) ;_ end of if
      (alert "             No pcd")
    ) ;_ end of if
  ) ;_ end of if
) ;_ end of defun

;;; This function will draw user
;;; defined hole pattern
(defun draw_pattern ()
  (info)
  (setq	pick_pcd (getpoint "\n Pick centre of pcd. ")
	ddpcd	 (atof ddpcd)
	num	 (atoi num)
	holedia	 (atof holedia)
  ) ;_ end of setq
  (setvar "osmode" 0)			; switches off object snaps
  (if (= offset "1")			; chooses whether to draw off centre or not
    (setq ra (/ 180 num))
    (setq ra 0)
  ) ;_ end of if
  (setq	pt1 (polar pick_pcd (Degrees->Radians ra) (/ ddpcd 2))
					; point of first hole
	pt2 (polar pt1 (Degrees->Radians (+ 180 ra)) holedia)
					; first point of hole c/line
	pt3 (polar pt2 (Degrees->Radians ra) (* holedia 2))
					; second point of hole c/line
  ) ;_ end of setq
  (command "circle"
	   pt1
	   (/ holedia 2)
	   "array"
	   "L"
	   ""
	   "P"
	   pick_pcd
	   num
	   "360"
	   "Y"
	   "layer"
	   "m"
	   "centre"
	   "c"
	   "green"
	   ""
	   "l"
	   "center"
	   ""
	   ""
	   "circle"
	   pick_pcd
	   (/ ddpcd 2)
	   "line"
	   pt2
	   pt3
	   ""
	   "array"
	   "L"
	   ""
	   "P"
	   pick_pcd
	   num
	   "360"
	   "Y"
  ) ;_ end of command
) ;_ end of defun


;;; This function will draw an
;;; angled hole pattern.
(defun draw_angpattern ()
  (info)
  (setq	pick_pcd (getpoint "\n Pick centre of pcd. ")
	ddpcd	 (atof ddpcd)
	num	 (atof num)
	holedia	 (atof holedia)
	halfpcd	 (/ ddpcd 2)
	minuspcd (- halfpcd holedia)
	pluspcd	 (+ halfpcd holedia)
	trighole (* halfpcd (cos (Degrees->Radians (atof ftang))))
	trigcl1	 (* minuspcd (cos (Degrees->Radians (atof ftang))))
	trigcl2	 (* pluspcd (cos (Degrees->Radians (atof ftang))))
	yvalue	 (cadr pick_pcd)
	count	 0
	pt7	 (polar pick_pcd (Degrees->Radians 180) halfpcd)
					; points for pcd ellipse
	pt8	 (polar pick_pcd (Degrees->Radians 0) halfpcd)
	pt9	 (polar	pick_pcd
			(Degrees->Radians 90)
			(* halfpcd (sin (Degrees->Radians (- 90 (atof ftang)))))
		 ) ;_ end of polar
  ) ;_ end of setq
  (setvar "osmode" 0)			; switches off object snaps
  (mark)
  (command "layer"  "m"	     "centre" "c"      "green"	""
	   "l"	    "center" ""	      ""       "ellipse"
	   pt7	    pt8	     pt9
	  ) ;_ end of command
   (if (= offset "1")			; chooses whether to draw off centre or not
    (setq ra (Degrees->Radians (/ 180 num)))
    (setq ra 0)
  ) ;_ end of if
  (while (< count num)			; p1 = centre of hole
    (setq p1  (list (car (polar pick_pcd ra halfpcd))
		    (+ yvalue
		       (* (sin ra) trighole) ;_ end of *
		    ) ;_ end of +
	      ) ;_ end of list
	  ra  (+ ra (Degrees->Radians (/ 360 num)))
	  el1 (polar p1 (Degrees->Radians 180) (/ holedia 2))
					; works out hole ellipse points
	  el2 (polar p1 (Degrees->Radians 0) (/ holedia 2))
	  el3 (polar
		p1
		(Degrees->Radians 90)
		(* (/ holedia 2)
		   (sin (Degrees->Radians (- 90 (atof ftang))))
		) ;_ end of *
	      ) ;_ end of polar
    ) ;_ end of setq
    (setq la (list (car (polar pick_pcd ra minuspcd))
					;centre line point
		   (+ yvalue (* (sin ra) trigcl1))
	     ) ;_ end of list
	  lb (list (car (polar pick_pcd ra pluspcd)) ;centre line point
		   (+ yvalue (* (sin ra) trigcl2))
	     ) ;_ end of list
    ) ;_ end of setq
    (command "layer" "m"     "centre"	     "c"     "green" ""
	     "l"     "center"	     ""	     ""	     "line"  la
	     lb	     ""
	    ) ;_ end of command
 ;_ end of command
    (setvar "clayer" oldlayer)
    (command "ellipse"
	     el1
	     el2
	     el3
    ) ;_ end of command
    (setq count (1+ count))
  ) ;_ end of while
  (setvar "osmode" oldosmode)
  (prompt "\nRotation Angle : ")
  (command "ROTATE" (catch) "" pick_pcd pause)
) ;_ end of defun

;;; This function will inform if any info is 
;;; missing in hole pattern dialog box when trying to draw
(defun info ()
  (if (or ddpcd)
    (if	(/= ddpcd "")
      (if (or holedia)
	(if (/= holedia "")
	  (if (or num)
	    (if	(/= num "")
	      (if
		(>= (* (atof num) (atof holedia)) (* (atof ddpcd) pi))
		 (alert "    Too many holes??")
	      ) ;_ end of if
	      (progn ((alert "           No hole dia") (exit)))
	    ) ;_ end of if
	    (progn ((alert "           No hole dia") (exit)))
	  ) ;_ end of if
	  (progn ((alert "    No. of holes not given") (exit)))
	) ;_ end of if
	(progn ((alert "    No. of holes not given") (exit)))
      ) ;_ end of if
      (progn ((alert "             No pcd") (exit)))
    ) ;_ end of if
    (progn ((alert "             No pcd") (exit)))
  ) ;_ end of if
) ;_ end of defun

;;; This function will draw a flat flange
(defun draw_flatFlange ()
  (setq	pick_cen (getpoint "\n Pick centre of flange. ")
	yvalue	 (cadr pick_cen)
	pt1	 (polar pick_cen (Degrees->Radians 90) (/ fod 2))
	pt2	 (polar pt1 (Degrees->Radians 180) thkx)
	pt3	 (polar pt2 (Degrees->Radians 270) fod)
	pt4	 (polar pt3 (Degrees->Radians 0) thkx)
	c1	 (list (+ (car pick_cen) (* thkx 0.5)) (+ yvalue (/ pcd 2)))
	c2	 (polar c1 (Degrees->Radians 180) (* thkx 2))
	c3	 (polar c2 (Degrees->Radians 270) pcd)
	c4	 (polar c3 (Degrees->Radians 0) (* thkx 2))
  ) ;_ end of setq
  (setvar "osmode" 0)			; switches off object snaps
  (mark)
  (command "line" pt1	 pt2	pt3    pt4    "c"    "layer"
	   "m"	  "centre"	"c"    "green"	     ""	    "l"
	   "center"	 ""	""     "line" c1     c2	    ""
	   "line" c3	 c4	""
	  ) ;_ end of command
   (setvar "osmode" oldosmode)
  (prompt "\nRotation Angle : ")
  (command "ROTATE" (catch) "" pick_cen pause)
) ;_ end of defun

;;; This function will draw a raised flange
(defun draw_raisedFlange ()
  (setq	pick_cen (getpoint "\n Pick centre of flange. ")
	yvalue	 (cadr pick_cen)
	thkx	 (- thkx hgt)
	pt1	 (polar pick_cen (Degrees->Radians 90) (/ fod 2))
	pt2	 (polar pt1 (Degrees->Radians 180) thkx)
	pt3	 (polar pt2 (Degrees->Radians 270) fod)
	pt4	 (polar pt3 (Degrees->Radians 0) thkx)
	r1	 (polar pt2 (Degrees->Radians 270) (- (/ (- fod rdi) 2) hgt))
	r2	 (polar r1 (Degrees->Radians 225) (* (sqrt 2) hgt))
	r3	 (polar r2 (Degrees->Radians 270) rdi)
	r4	 (polar r3 (Degrees->Radians 315) (* (sqrt 2) hgt))
	c1	 (list (+ (car pick_cen) (* thkx 0.5)) (+ yvalue (/ pcd 2)))
	c2	 (polar c1 (Degrees->Radians 180) (* thkx 2))
	c3	 (polar c2 (Degrees->Radians 270) pcd)
	c4	 (polar c3 (Degrees->Radians 0) (* thkx 2))
  ) ;_ end of setq
  (setvar "osmode" 0)			; switches off object snaps
  (mark)
  (command "line" pt1	 pt2	pt3    pt4    "c"    "arc"  r2
	   "e"	  r1	 "r"	hgt    "arc"  r4     "e"    r3
	   "r"	  hgt	 "line"	r2     r3     ""     "layer"
	   "m"	  "centre"	"c"    "green"	     ""	    "l"
	   "center"	 ""	""     "line" c1     c2	    ""
	   "line" c3	 c4	""
	  ) ;_ end of command
   (setvar "osmode" oldosmode)
  (prompt "\nRotation Angle : ")
  (command "ROTATE" (catch) "" pick_cen pause)
) ;_ end of defun

;;; This function will write 
;;; out the flange notes
(defun notes ()
  (setvar "osmode" 0)
  (if (= offset "1")
    (setq off_on "OFF")
    (setq off_on "ON")
  ) ;_ end of if
  (setq	notesize (nth (atoi size) flsize)
	line1	 (strcat notesize " FLANGE")
	line3	 (strcat (itoa (fix bqt))
			 " HOLES %%C"
			 (itoa (fix bdi))
			 " ON A"
		 ) ;_ end of strcat
	line4	 (strcat (itoa (fix pcd)) " PCD " off_on " CENTRE")
  ) ;_ end of setq
  (setq pick_note (getpoint "\n Pick place for notes. "))
  (command "text"
	   pick_note
	   (* dscale textheight)
	   ""
	   line1
	   "text"
	   ""
	   line2
	   "text"
	   ""
	   line3
	   "text"
	   ""
	   line4
  ) ;_ end of command
  (setvar "osmode" oldosmode)
) ;_ end of defun


;;; This function will read a list 
;;; and create the variable "dlist"
(defun grab ()
  (setq	dlist nil
	sizex (strcat "*" sizex)
	file  (findfile "flange.lst")
	fp    (open file "r")
	item  (read-line fp)
  )					;setq
  (while item
    (if	(= item sizex)
      (setq data (read-line fp)
	    item nil
      )					;setq
      (setq item (read-line fp))
    )					;if
  )					;while
  (if data
    (progn
      (setq maxs  (strlen data)
	    count 1
	    chrct 1
      )					;setq
      (while (< count maxs)
	(if (/= "," (substr data count 1))
	  (setq chrct (1+ chrct))
	  (setq	numb  (atof (substr data (1+ (- count chrct)) chrct))
		dlist (append dlist (list numb))
		chrct 1
	  )				;setq
	)				;if
	(setq count (1+ count))
      )					;while
      (setq numb  (atof (substr data (1+ (- count chrct))))
	    dlist (append dlist (list numb))
      )					;setq
    )					;progn
  )					;if data
  (close fp)
)					;defun

;;; This function will reset the original enviroment.
(defun res_env ()
  (setvar "blipmode" oldblip)
  (setvar "cmdecho" oldecho)
  (setvar "osmode" oldosmode)
  (setvar "clayer" oldlayer)
  (setq *error* olderror)
  (princ)
  (princ)
) ;_ end of defun

;;; This function will reset the original enviroment,
;;; display an exit message and exit cleanly. 
(defun err_hand	(msg)
  (setvar "blipmode" oldblip)
  (setvar "cmdecho" oldecho)
  (setvar "osmode" oldosmode)
  (setvar "clayer" oldlayer)
  (setq *error* olderror)
  (princ
    (strcat "\n*** Exit out of " appname " ***\n")
  ) ;_ end of prompt
  (princ)
) ;_ end of defun

;;; MARK marks the database for use with CATCH.
;;; Written by Kenny Ramage Feb. '95
(defun MARK (/ val)
  (setq val (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (if (setq #mark (entlast))
    nil
    (progn
      (entmake '((0 . "POINT") (10 0.0 0.0 0.0)))
      (setq #mark (entlast))
      (entdel #mark)
    ) ;_ end of progn
  ) ;_ end of if
  (setvar "cmdecho" val)
  (princ)
) ;_ end of defun

;;;CATCH starts at MARK and retrieves to the end of the database.
;;;*-------------------------------------------------------------------
(defun CATCH (/ ss)
  (if #mark
    (progn
      (setq ss (ssadd))
      (while (setq #mark (entnext #mark))
	(ssadd #mark ss)
      )					;while 
      ss
    )					;progn then
    (prompt "\n#MARK not set. Run MARK before CATCH.\n") ;else
  )					;if
)					;defun
(princ)
					;* end of CATCH.LSP


;;; Main program
(defun C:Flange	()
  (set_env)				; sets the enviroment
  (DialogBox)				; loads dialog box
  (if (= flag 1)
    (check)
  ) ;_ end of if
  (if (= flag 10)
    (notes)
  ) ;_ end of if
  (res_env)				; resets the original enviroment
  (princ)
) ;_ end of defun

(princ
  "\nFlange program by Peter Best is loaded: \nType \"flange\" to start "
) ;_ end of princ
(princ)

