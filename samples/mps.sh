#!/bin/sh
#
# mps : display MVS processes that are active.
#   a simple program to put the opercmd d a,all onto single lines to make parsing easier
#
#
# Copyright IBM Corp. 2021
#
raw=`opercmd 'd a,all' | tail +6`
echo "${raw}" | awk '
	BEGIN { text = "" } 
	{ 
		sub(/^[ ]+/,""); 
		if (NF == 7) {
			line = substr($0,1,18) "~~~~~~~" substr($0,26)
		} else {
			line = $0
		}
		if (NF > 6 && text != "") { 
			print text
			text="" 
		} 
		text=text line " " 
	} 
	END { print text }'

