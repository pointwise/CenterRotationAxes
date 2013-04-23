#
# Copyright 2009 (c) Pointwise, Inc.
# All rights reserved.
# 
# This sample Pointwise script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.  
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

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

  pack [label .commands.logo -image [pwLogo] -bd 0 -relief flat] \
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

proc pwLogo {} {
  set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

  return [image create photo -format GIF -data $logoData]
}

init
makeWindow

tkwait window .

#
# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT.  TO THE MAXIMUM EXTENT PERMITTED 
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY 
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES 
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE 
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE 
# FAULT OR NEGLIGENCE OF POINTWISE.
#
