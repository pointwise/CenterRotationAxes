#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

###############################################################################
##
## BrickBlock.glf
##
## Script with Tk interface to create a rectangular structured block
##
###############################################################################

package require PWI_Glyph 2

pw::Script loadTk


############################################################################
# init: Set the defaults for the boxes
############################################################################
proc init { } {
  global x y z orix oriy oriz lastx lasty lastz
  set view [pw::Display getCurrentView]
  set t [lindex $view 0]
  set lastx [ set orix [lindex $t 0] ]
  set lasty [ set oriy [lindex $t 1] ]
  set lastz [ set oriz [lindex $t 2] ]
  set x [lindex $t 0]
  set y [lindex $t 1]
  set z [lindex $t 2]
}

############################################################################
# setStatus: Colorize text fields based on data validity
############################################################################
proc setStatus { } {
  global x y z

  set nok 0
  foreach box { x y z } {
    set value [eval "set $box"]
    set ok [string is double $value]
    if { $ok } {
      .inputs.$box.ent$box configure -background "#FFFFFF"
    } else {
      .inputs.$box.ent$box configure -background "#FFCCCC"
      if { $nok == 0 } {
        focus .inputs.$box.ent$box
      }
      incr nok
    }
  }

  if { $nok != 0 } {
    .commands.go configure -state disabled
  } else {
    .commands.go configure -state normal
  }

  return $nok
}

############################################################################
# orient: set the current view position
############################################################################
proc orient { x y z } {
  global orix oriy oriz 
  if [ expr [string compare "$x" ""]==0 ] { set tx $orix } else { set tx $x }
  if [ expr [string compare "$y" ""]==0 ] { set ty $oriy } else { set ty $y }
  if [ expr [string compare "$z" ""]==0 ] { set tz $oriz } else { set tz $z }
  if { [string is double $x] != 1 } { focus .inputs.x.entx; return 0 }
  if { [string is double $y] != 1 } { focus .inputs.y.enty; return 0 }
  if { [string is double $z] != 1 } { focus .inputs.z.entz; return 0 }
  set view [pw::Display getCurrentView]
  set center [list $tx $ty $tz]
  set view [lreplace $view 0 0 $center]
  pw::Display setCurrentView $view
  pw::Display update
}

############################################################################
# updateEntry: check a field value and schedule a delayed orient
############################################################################
proc updateEntry { box } {
  upvar $box value
  setStatus
  if [string is double -strict $value] {
    after 500 updateConditional \"$value\" $box
  }
}

############################################################################
# focusEntry: change field focus
############################################################################
proc focusEntry { box } {
  .inputs.$box.ent$box selection range 0 100
  setStatus
}

############################################################################
# updateConditional: re-orient if the values are the same
############################################################################
proc updateConditional { value box } {
  upvar $box bvalue
  if [ expr [string compare [focus] .inputs.$box.ent$box] == 0 ] {
    global x y z
    catch {
      if { $bvalue == $value } {
        orient $x $y $z
      }
    } 
  }
}

############################################################################
# makeWindow: make the TK interface
############################################################################
proc makeWindow {} {
  global x y z

  wm title . "Center Rotation Axes"

  label .title -text "Type In Rotation Point"
  set font [font actual [.title cget -font] -family]
  .title configure -font [font create -family $font -weight bold]
  pack .title -expand 1 -side top

  frame .hr1 -bd 1 -height 2 -relief sunken
  pack .hr1 -side top -fill x -expand 0 -pady 2

  frame .inputs
  foreach t {x y z} {
    frame .inputs.$t
    label .inputs.$t.lbl$t -text "$t:"
    entry .inputs.$t.ent$t -textvariable $t -width 7 -validate focusout \
      -validatecommand {
        if [ expr [string is double -strict %P] != 1 ] {
          orient $x $y $z
          return 1
        }
        return 0
      } \
      -invcmd {
        focus %W
        bell
        after idle {%W config -validate focusout}
      }

    pack .inputs.$t.lbl$t -side left -expand 0 -padx 4
    pack .inputs.$t.ent$t -side right -expand 0 -padx 4
    pack .inputs.$t -pady 3 -padx 5 -side left
    bind .inputs.$t.ent$t <KeyPress-Return> { orient $x $y $z }
  }
  pack .inputs -fill x

  button .inputs.restore -text "Reset" -command {
    set x $lastx
    set y $lasty
    set z $lastz
    orient $x $y $z
    focus .inputs.x.entx
    .inputs.x.entx selection range 0 100
  }
  pack .inputs.restore -side right -padx 3

  frame .commands 
  button .commands.apply -text "Apply" -command {
    set lastx $x
    set lasty $y
    set lastz $z
    orient $x $y $z
    focus .inputs.x.entx
  }
  button .commands.go -text "OK" -command {
    orient $x $y $z
    exit
  }
  button .commands.exit -text "Cancel" -command {
    orient $orix $oriy $oriz
    exit
  }

  frame .hr2 -bd 1 -height 2 -relief sunken
  pack .hr2 -side top -fill x -expand 0 -pady 2

  pack [label .commands.logo -image [cadenceLogo] -bd 0 -relief flat] \
      -side left -padx 5

  pack .commands -fill x -side bottom
  pack .commands.apply .commands.exit .commands.go -padx 2 -pady 1 -side right

  bind .commands.go <KeyPress-Return> { %W invoke }
  bind .commands.apply <KeyPress-Return> { %W invoke }
  bind .commands.exit <KeyPress-Return> { %W invoke }
  bind .inputs.restore <KeyPress-Return> { %W invoke }

  bind .inputs.x.entx <KeyRelease> { updateEntry x }
  bind .inputs.y.enty <KeyRelease> { updateEntry y }
  bind .inputs.z.entz <KeyRelease> { updateEntry z }

  bind .inputs.x.entx <FocusIn> { focusEntry x }
  bind .inputs.y.enty <FocusIn> { focusEntry y }
  bind .inputs.z.entz <FocusIn> { focusEntry z }

  bind . <KeyPress-Escape> { .commands.exit invoke }
  bind . <Control-KeyPress-Return> { .commands.go invoke }

  focus .inputs.x.entx
  ::tk::PlaceWindow . widget
}

proc cadenceLogo {} {
  set logoData "
R0lGODlhgAAYAPQfAI6MjDEtLlFOT8jHx7e2tv39/RYSE/Pz8+Tj46qoqHl3d+vq62ZjY/n4+NT
T0+gXJ/BhbN3d3fzk5vrJzR4aG3Fubz88PVxZWp2cnIOBgiIeH769vtjX2MLBwSMfIP///yH5BA
EAAB8AIf8LeG1wIGRhdGF4bXD/P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIe
nJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtdGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1w
dGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1Nzo
wMSAgICAgICAgIj48cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudy5vcmcvMTk5OS8wMi
8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmY6YWJvdXQ9IiIg/3htbG5zO
nhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0
cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUcGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh
0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0idX
VpZDoxMEJEMkEwOThFODExMUREQTBBQzhBN0JCMEIxNUM4NyB4bXBNTTpEb2N1bWVudElEPSJ4b
XAuZGlkOkIxQjg3MzdFOEI4MTFFQjhEMv81ODVDQTZCRURDQzZBIiB4bXBNTTpJbnN0YW5jZUlE
PSJ4bXAuaWQ6QjFCODczNkZFOEI4MTFFQjhEMjU4NUNBNkJFRENDNkEiIHhtcDpDcmVhdG9yVG9
vbD0iQWRvYmUgSWxsdXN0cmF0b3IgQ0MgMjMuMSAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpZW
RGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGE1NjBhMzgtOTJiMi00MjdmLWE4ZmQtM
jQ0NjMzNmNjMWI0IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjBhNTYwYTM4LTkyYjItNDL/
N2YtYThkLTI0NDYzMzZjYzFiNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g
6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovp6Ofm5e
Tj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66tr
KuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0
c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj0
8Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQ
QDAgEAACwAAAAAgAAYAAAF/uAnjmQpTk+qqpLpvnAsz3RdFgOQHPa5/q1a4UAs9I7IZCmCISQwx
wlkSqUGaRsDxbBQer+zhKPSIYCVWQ33zG4PMINc+5j1rOf4ZCHRwSDyNXV3gIQ0BYcmBQ0NRjBD
CwuMhgcIPB0Gdl0xigcNMoegoT2KkpsNB40yDQkWGhoUES57Fga1FAyajhm1Bk2Ygy4RF1seCjw
vAwYBy8wBxjOzHq8OMA4CWwEAqS4LAVoUWwMul7wUah7HsheYrxQBHpkwWeAGagGeLg717eDE6S
4HaPUzYMYFBi211FzYRuJAAAp2AggwIM5ElgwJElyzowAGAUwQL7iCB4wEgnoU/hRgIJnhxUlpA
SxY8ADRQMsXDSxAdHetYIlkNDMAqJngxS47GESZ6DSiwDUNHvDd0KkhQJcIEOMlGkbhJlAK/0a8
NLDhUDdX914A+AWAkaJEOg0U/ZCgXgCGHxbAS4lXxketJcbO/aCgZi4SC34dK9CKoouxFT8cBNz
Q3K2+I/RVxXfAnIE/JTDUBC1k1S/SJATl+ltSxEcKAlJV2ALFBOTMp8f9ihVjLYUKTa8Z6GBCAF
rMN8Y8zPrZYL2oIy5RHrHr1qlOsw0AePwrsj47HFysrYpcBFcF1w8Mk2ti7wUaDRgg1EISNXVwF
lKpdsEAIj9zNAFnW3e4gecCV7Ft/qKTNP0A2Et7AUIj3ysARLDBaC7MRkF+I+x3wzA08SLiTYER
KMJ3BoR3wzUUvLdJAFBtIWIttZEQIwMzfEXNB2PZJ0J1HIrgIQkFILjBkUgSwFuJdnj3i4pEIlg
eY+Bc0AGSRxLg4zsblkcYODiK0KNzUEk1JAkaCkjDbSc+maE5d20i3HY0zDbdh1vQyWNuJkjXnJ
C/HDbCQeTVwOYHKEJJwmR/wlBYi16KMMBOHTnClZpjmpAYUh0GGoyJMxya6KcBlieIj7IsqB0ji
5iwyyu8ZboigKCd2RRVAUTQyBAugToqXDVhwKpUIxzgyoaacILMc5jQEtkIHLCjwQUMkxhnx5I/
seMBta3cKSk7BghQAQMeqMmkY20amA+zHtDiEwl10dRiBcPoacJr0qjx7Ai+yTjQvk31aws92JZ
Q1070mGsSQsS1uYWiJeDrCkGy+CZvnjFEUME7VaFaQAcXCCDyyBYA3NQGIY8ssgU7vqAxjB4EwA
DEIyxggQAsjxDBzRagKtbGaBXclAMMvNNuBaiGAAA7"

  return [image create photo -format GIF -data $logoData]
}

init
makeWindow

tkwait window .

#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
