#cmd template

$moduleUrl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/MasterPrnRepo.ps1"
$script = [scriptblock]::Create((Invoke-RestMethod -Method get -Uri $moduleUrl))
New-Module -Name wap.main -ScriptBlock $script | Out-Null


$r = Get-PrinterDriverFromURL -url $url -FileName "HP"
$prn = [Printer]::new("Test","10.1.1.111","HP","SG",$r)