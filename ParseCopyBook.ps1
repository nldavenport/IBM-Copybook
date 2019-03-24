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

Function Parse-CopyBook {
	<#
	.SYNOPSIS
		The Parse-CopyBook cmdlet converts file layout(s) to csv format.

	.DESCRIPTION
		The Parse-CopyBook cmdlet converts iSeries copybook layout(s) to csv formats to help read and translated COBOL.

	.PARAMETER filter
		Fully qualified path & filter

	.PARAMETER log
		Fully qualified log path & filter

	.EXAMPLE
		PS> Parse-CopyBook D:\Powershell\Copy\test.pdf
		-> 

	.LINK
		
	#>

	Param (
        [Parameter(Mandatory=$false)] [String]$Path = "D:\Powershell\COPYBOOKS",
        [Parameter(Mandatory=$false)] [String]$filter = "*.TXT",
        [Switch]$SQL,
        [Switch]$TXT,
        [Switch]$CSV
	)

	Begin {
#		Write-EventLog –LogName $logname -Source $logsource –EntryType Information –EventID 3 -Message "$PID,Parse-CopyBook,Begin,$filter"
        $ParseStart = Get-Date
        $TotalFiles = 0
        $TotalLines = 0

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
        if ($TXT) {
#                $TxtFile = $Output + ".txt"
            $TxtFile = 'FDFields.txt'
            $SW = New-Object System.IO.StreamWriter($TxtFile)
            $SW.WriteLine("Copybook,RegExp,Index,Level,Start,End,Length,Field,Type,Pic,Value,Occurs,Comp,Redefines")
        }
	}
	Process {
		$line = ""

		$files = Get-ChildItem $Path -Filter $filter -Name
		Foreach($file in $files) {
            $FileStart = Get-Date
            $TotalFiles += 1 #Count Files
            $FileLines = 0

            $Array = @()
            $Hash = @{}
			$Index = 0
			$Start = 0
			$End = 0

			$Copybook = $File.substring(0, $File.length - 4)

Write-Verbose "File: $file"
            $Output = (Split-Path $file -Leaf).Split(".")[0]

            if ($TXT) {
                $TxtFile = $Output + ".csv"
                $SW1 = New-Object System.IO.StreamWriter($TxtFile)
                $SW1.WriteLine("Copybook,RegExp,Index,Level,Start,End,Length,Field,Type,Pic,Value,Occurs,Comp,Redefines")
            }
			$text = Get-Content (Join-Path $Path $file)
			foreach ($strip in $text) {
				$length = $null
				$field = $null
				$type = $null
				$pic = $null
			   	$value = $null
				$occurs = $null
				$comp = $null
				$Redefines = $null
                $FileLines += 1 # Count lines in file
				if ($strip -notmatch '^.{6}\*' ) {
Write-Verbose "Strip: $strip $($strip.length)"
    				if ($strip.length -ge 6) {
                        $line += $strip.substring(6,$strip.length - 6)
                    }
					if ($line -match $CompletePattern) {
Write-Verbose "Line: $line"
                        $line = $matches.text
						$line -match $FieldPattern | Out-Null
						$level = $matches.level 
						$field = $matches.field
						$line -match $PicPattern | Out-Null
						$pic = $matches.pic
						if ($pic -ne $null) {
Write-Verbose "Pic: $pic"
							if ($pic -match $CharPattern) {
								$type = "char"
								[int]$length = 1
                                $RegPattern = '>[A-Z]{'
							}
							if ($pic -match $StringPattern) {
								$type = "string"
								[int]$length = $matches.chars
                                $RegPattern = '>[A-Z]{'
							}
							if ($pic -match $SimpleStringPattern) {
								$type = "string"
								[int]$length = $matches[0].length
                                $RegPattern = '>[A-Z]{'
							}
							if ($pic -match $IntPattern) {
								$type += "integer"
								if ($matches.digits -ne $null) {
									[int]$length += $matches.digits
								} else {
									[int]$length += $matches[0].length-1
								}
                                $RegPattern = '>[0-9]{'
							}
							if ($pic -match $SimpleIntPattern) {
								$type += "integer"
								[int]$length += $matches[0].length
                                $RegPattern = '>[0-9]{'
							}
							if ($pic -match $DoublePattern) {
								$type += "double"
								if ($matches.digits -ne $null) {
									[int]$length += $matches.digits
								} else {
									[int]$length += $matches[0].length-1
								}
                                $RegPattern = '>[0-9]{'
							}
							if ($pic -match $DecimalPattern) {
								if ($matches.decimals -ne $null) {
									[int]$length += $matches.decimals
								} else {
									[int]$length += $matches[0].length-1
								}
                                $RegPattern = '>[0-9\.]{'
							}
							if ($pic -match $PaddedPattern) {
Write-Verbose "Padded: $pic"
								$type = "padded"
								[int]$length = $matches[0].length
                                $RegPattern = '>[0-9-\.]{'
							}
						if ($pic -match $SignedPattern) {
								$type = "signed " + $type
								[int]$length++ | Out-Null 
                                $RegPattern = '>[0-9-\.]{'
							}
						}
						$line -match $ValuePattern | Out-Null
						if ($matches.value -ne $null) {
							$value = $matches.value
						}
						$line -match $ValuePattern2 | Out-Null
						if ($matches.value -ne $null) {
							$value = $matches.value
						}
						$line -match $OccursPattern | Out-Null
						$occurs = $matches.occurs
						$line -match $CompPattern | Out-Null
						$comp = $matches.comp
						if ($comp -ne $null) {$length = [int][math]::Ceiling($length/2)}
						$line -match $IndexedPattern | Out-Null
						$indexed = $matches.indexed
						$line -match $RedefinePattern | Out-Null
						$redefines = $matches.redefines
                        if ($Pic -ne $null) {
                            $RegExp = '(?<' + $field + $RegPattern + $length + '})'
                        }
                        else {
                            $RegExp = ''
                        }

						$Index ++
                        if ($redefines -ne $null) {
                            $Start = $Hash[$redefines]
                        } else {
    						if ($Level -gt $PrevLevel) {
	    						$Start = $End
		    				} else {
			    				$Start = $End + 1
				    		}
                        }
						if ($Start -eq 0) {$Start = 1}
						$End = $Start
						if ($length -gt 0) {$End += $length - 1}
						$PrevLevel = $Level

Write-Verbose "Data: $Copybook,$RegExp,$Index,$level,$Start,$End,$length,$field,$type,$pic,$value,$occurs,$comp,$Redefines"
                        if ($TXT) {
                            $SW.WriteLine("$Copybook,$RegExp,$Index,$level,$Start,$End,$length,$field,$type,$pic,$value,$occurs,$comp,$Redefines")
                            $SW1.WriteLine("$Copybook,$RegExp,$Index,$level,$Start,$End,$length,$field,$type,$pic,$value,$occurs,$comp,$Redefines")
                        }
                        if ($CSV) {
    						$obj = New-Object System.Object
	    					$obj | Add-Member -type NoteProperty -name Copybook -value $Copybook
		    				$obj | Add-Member -type NoteProperty -name RegExp -value $RegExp
			    			$obj | Add-Member -type NoteProperty -name Index -value $Index
				    		$obj | Add-Member -type NoteProperty -name Level -value $level
					    	$obj | Add-Member -type NoteProperty -name Start -value $Start
						    $obj | Add-Member -type NoteProperty -name End -value $End
    						$obj | Add-Member -type NoteProperty -name Length -value $length
	    					$obj | Add-Member -type NoteProperty -name Field -value $field
		    				$obj | Add-Member -type NoteProperty -name Type -value $type
			    			$obj | Add-Member -type NoteProperty -name Pic -value $pic
			   	    		$obj | Add-Member -type NoteProperty -name Value -value $value
					    	$obj | Add-Member -type NoteProperty -name Occurs -value $occurs
						    $obj | Add-Member -type NoteProperty -name Comp -value $comp
    						$obj | Add-Member -type NoteProperty -name Redefines -value $Redefines
	    					$Array += $obj
                        }
                        if (! $Hash.ContainsKey($field)) {
                            $Hash.Add($field,$Start)
                        }

						$line = ""
						$type = ""
						$length = 0
						$value = ""
					}
				}
			}
            if ($CSV) {
    			$CSVFile = $Copybook + ".csv"
Write-Verbose $CSVFile
	    		$Array | Export-Csv -path $CSVfile -NoTypeInformation
		    	$Array | Export-Csv -path 'FDFields.csv' -NoTypeInformation -Append
            }
            if ($TXT) {
                $SW1.Close()
            }
            Write-Host "$TotalFiles $Copybook $FilePages $FileLines" ((Get-Date) - $FileStart)
            $TotalLines += $FileLines
            $TotalPages += $FilePages
		}
	}
	End {
        if ($TXT) {
            $SW.Close()
        }
        Write-Host "Total: $TotalFiles $TotalPages $TotalLines" ((Get-Date) - $ParseStart)
#	  	Write-EventLog –LogName $logname -Source $logsource –EntryType Information –EventID 3 -Message "$PID,Parse-CopyBook,End,$filter"
	}
}