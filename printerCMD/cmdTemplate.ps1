#cmd template
using module ./MasterPrnRepo.psm1 # Change the path to c:\windows\temp\ after uploading within JC cmd
#$moduleUrl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/MasterPrnRepo.psm1"
#$script = [scriptblock]::Create((invoke-WebRequest -Uri $moduleUrl -UseBasicParsing).content)
#New-Module -Name prnt.main -ScriptBlock $script | Out-Null



$url = 
$r = Get-PrinterDriverFromURL -url $url -FileName "HP"
$prn = [Printer]::new("Test","10.1.1.111","HP","SG",$r)