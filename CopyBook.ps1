<#
.NOTES
	Author: Nathan Davenport
	Date  : yyyy/mm/dd

	Copyright © 1984-  DRock Development. IsladBoy Holdings. All rights reserved.
	Free for all users, as long as this header is included

.SYNOPSIS
	Script is an assortment of ... 
.DESCRIPTION
	The Script module of cmdlets is a group of tools to ... 
#>

#region RegEx
$CompletePattern = '^(?<text>.+)(\.$|\.\s)'
#$CompletePattern = "^(?<text>[A-Z0-9-+():\.\s\x5f]+)\.*"
$FieldPattern = '(?<level>[0-9]{2})\s+(?<field>[\S-]+)'
$PicPattern = 'PIC\s+(?<pic>[-/+$,(\d):A-Z*\.]+)'
	$CharPattern = '^x$'
	$StringPattern = 'x\((?<chars>[\d]+)\)'
    $SimpleStringPattern = '^[A-Z]+$'
	$SignedPattern = 's'
	$PaddedPattern = '^Z+9\.*9*\-*$'
	$IntPattern = '^[s]?9+\((?<digits>[\d]+)\)$|^9$'
	$SimpleIntPattern = '^9+$'
	$DoublePattern = '9+\((?<digits>[\d]+)\)v|9+v'
	$DecimalPattern = 'v9\((?<decimals>[\d]+)\)|v[9]+'
$ValuePattern = '\s+VALUE\s+(?<value>[a-zA-Z0-9\+\-]+)'
$ValuePattern2 = '\s+VALUE\s+\x27(?<value>[a-zA-Z0-9\+\-]+)\x27'
$OccursPattern = '\s+OCCURS\s+(?<occurs>\d+) TIMES'
$CompPattern = '\s+(?<comp>COMP[-123]*)'
$IndexedPattern = '\s+INDEXED BY\s+(?<indexed>[\S-]+)'
$RedefinePattern = '\s+REDEFINES\s+(?<redefines>[\S-]+)'
#endregion