//   Flange Dialog Control Language File  
//   for Flange.lsp                       
//   Peter Best   7/10/98                 

flange : dialog {
             label = "Flanges and hole patterns";
          : row {
             fixed_width = true;
          : toggle {
            key  = "pipeod";
            label = "Pipe OD";
            }
            spacer_1;
          : text {
              label = "Nominal Bore";
            }
          : popup_list{           
              key = "size";
              list = "15\n20\n25\n32\n40\n50\n65\n80\n90"
                     "\n100\n125\n150\n200\n250\n300\n350"
                     "\n375\n400\n450\n500\n550\n600";
              edit_width = 5;
                 value = 9;
              }
           }// end of row
         : boxed_column {
          label = "Selection";
	 : row {
         : radio_column {
          key = "select";
         : radio_button {
                key = "sabs";
                label = "SABS 1123";
                value = 1;
              }
         : radio_button {
              key = "bs";
              label = "BS 4504";
            }
         : radio_button {
              key = "ansi";
              label = "ANSI B16.5";
            }  
         : radio_button {
              key = "as";
              label = "AS 2129";
            }
         : radio_button {
              key = "pat";
              label = "Hole pattern";
            }
            }// end of radio column
         : radio_column {
	 : popup_list{           
              key = "typ1";
              list = "    600\n   1000\n   1600\n   2500";
              edit_width = 9;
              value = 1;
              fixed_width = true;
            }                       
 	 : popup_list{           
              key = "typ2";
              list = "Table 6\nTable 10\nTable 16\nTable 25";
              edit_width = 9;
              value = 1;
              fixed_width = true;
            }            
 	 : popup_list{           
              key = "typ3";
              list = "   150#\n   300#\n   400#\n   600#";
              edit_width = 9;
              fixed_width = true;
              value =0;
            }            
	 : popup_list{           
              key = "typ4";
              list = " Table D\n Table E\n Table F\n Table H";
              edit_width = 9;
              fixed_width = true;
              value = 0;
            }
            spacer_1;
            spacer_1;
            }// end of radio column
            }// end of row
            }// end of boxed column
        : boxed_column {
          label = "Sizes";
        : row {
        : text {          
          label = "O.D.";
        }
        : text {
          label = "I.D.";
        }
        : text {
          label = "Pcd.";
        }
        : text {
          label = "No.";
        }
        : text {
          label = "Dia.";
        }
        : text {
          label = "Thick";
        }
        }
        : row {
        : text {
          key = "dod";
          width = 3;
        }
        : text {
          key = "did";
          width = 4;
        }
        : text {
          key = "dpcd";
          width = 4;
        }
        : text {
          key = "dno";
          width = 3;
        }
        : text {
          key = "ddia";
          width = 4;
        }
        : text {
          key = "dthick";
          width = 4;
        }
        }
        }
         : boxed_column {
             label = "View";
         :radio_row {
            key = "view";
         : radio_button {
                key = "front";
                label = "Plan";
                value = 1;                
                }
         : radio_button {
                key = "ff";
                label = "FF";
                }
              : radio_button {
                key = "rf";
                label = "RF";
              }
              }// end of radio_row
              
         : row {
         : toggle {
            key  = "offset";
            label = "Offset";
            }
            spacer_1;
            spacer_1;
         : popup_list{           
              key = "ddthick";
              list = "Std\n6\n8\n10\n12\n14\n16\n18\n20"
                     "\n22\n24\n26\n28\n30\n32\n34\n36"
                     "\n38\n40\n45\n50\n55\n60";
              edit_width = 5;
              fixed_width = true;
              value = 0;
              }
         :text {
            key = "textt";
              label = "Thickness";
              }
              }// end of row
        : row {
             fixed_width = true;
        : edit_box{
             key = "ftang";
               }  
         :text {
            key = "texta";
              label = "Angle from plan";
              }
              }// end of row
            spacer_1;
              }// end of boxed_column

        : row {
        : image {
                   key = "im" ;
                   height = 1.0 ;
                   width = 3.7 ;
              fixed_width = true ;
                   }             
         : button {          
              label = "Notes" ;
              key = "notes";
              is_default = true ;
              fixed_width = true ;
              is_cancel = true ;
            }
        : button {          // "OK" button renamed
              label = "Draw" ;
              key = "accept";
              is_default = true ;
              fixed_width = true ;
              is_cancel = true ;
            }
        : retirement_button {
                label = "Exit";
                key = "exit";
                is_cancel = true;
               fixed_width = true;
              }
            }// end of row
           }// end of dialog

pattern : dialog {
             label = "Hole pattern";
         : boxed_column {
          label = "Input";
         : row {
         :text {
          label = "PCD.";
          }
        : edit_box{
          key = "ddpcd";
           edit_width = 5;
          }  
          }// end of row
          : row {
         :text {
          label = "No. of holes";
          }
        : edit_box{
          key = "num";
           edit_width = 5;
          }  
          }// end of row
          : row {
         :text {
          label = "Hole dia.";
          }
        : edit_box{
          key = "holedia";
           edit_width = 5;
          }
          }// end of row
          spacer_1;          
          ok_cancel;
          }// end of boxed_column
          }