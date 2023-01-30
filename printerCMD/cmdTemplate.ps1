#cmd template
using module "c:\windows\temp\MasterPrnRepo.psm1" # Change the path to c:\windows\temp\ after uploading within JC cmd

# Run the lines before using the module, JC cmd wont have this issue
#$moduleUrl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/MasterPrnRepo.psm1"
#$script = [scriptblock]::Create((invoke-WebRequest -Uri $moduleUrl -UseBasicParsing).content)
#$script | Out-File MasterPrnRepo.psm1
#New-Module -Name prnt.main -ScriptBlock $script | Out-Null

$port = 9100
$HPRrns = @()
$HPurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/hp.zip"
$r = Get-PrinterDriverFromURL -url $HPurl -FileName "HP"
$HPRrns += [Printer]::new("Test01","10.1.1.111","HP","SG",$r)
$HPRrns += [Printer]::new("Test02","10.1.1.112","HP","SG",$r)


foreach ($p in $HPRrns){
    $p.InstallDriver()
    sleep 20
    $p.InstallPrinter($port)
}

#Cleanning up 
$unzipPath = $r.Trim('.zip')

Remove-Item -Path $r -Force -Verbose
Remove-Item -Path $unzipPath -Recurse -Force -Verbose
