# Install Printer JC CMD template
# Get the latest module at:
# https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/MasterPrnRepo.psm1

using module "c:\windows\temp\MasterPrnRepo.psm1" # Change the path if you have a customised location storing the uploaded file

# Creating printer objects
$port = 9100
$Prns = @()

# Building the Printer Parameters

## HP Printer
$HPurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/hp.zip"
$ReDriverPathHP = Get-PrinterDriverFromURL -url $HPurl -FileName "HP"
$HP_Prn01 = "HP_Test01" # Name your printer as you wish
$Prns += [Printer]::new($HP_Prn01,"your_printer_ip","HP","your_country_code",$ReDriverPathHP)


## Cannon Printer
$CNurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/canon.zip"
$ReDriverPathCN = Get-PrinterDriverFromURL -url $CNurl -FileName "Canon"
$CN_Prn01 = "CN_Test01" #Name your printer as you wish
$Prns += [Printer]::new($CN_Prn01,"your_printer_ip","canon","your_country_code",$ReDriverPathCN)

## Brother Printer
$BRurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/brother.zip"
$ReDriverPathBR = Get-PrinterDriverFromURL -url $BRurl -FileName "Brother"
$BR_Prn01 = "BR_Test01" #Name your printer as you wish
$Prns += [Printer]::new($BR_Prn01,"your_printer_ip","brother","your_country_code",$ReDriverPathBR)


# Creating A Recycle Bin
$RB = @()
$RB += $ReDriverPathHP
$RB += $ReDriverPathCN
$RB += $ReDriverPathBR

$RB += "c:\windows\temp\MasterPrnRepo.psm1"
$RB += $ReDriverPathHP + '.zip'
$RB += $ReDriverPathCN + '.zip'
$RB += $ReDriverPathBR + '.zip'

# Install the printers
foreach ($p in $Prns){
    # Determine the driver name 
    $dn = ""               
    switch ($p.drivername) {
        "HP" { $dn = "HP Universal Printing PCL 6" }
        "Canon" { $dn  = "Canon Generic Plus PCL6" }
        "Brother" { $dn  = "Brother Mono Universal Printer (PCL)" }
    }
    $driExist =  Get-PrinterDriver | ? {$_.name -like "*$dn*"}
    if ($null -eq $driExist){
        $p.InstallDriver($dn)
        sleep 20   
    
    }      
    $p.InstallPrinter($port,$dn)
}
 


#Cleanning up 
foreach ($item in $RB){

    Remove-Item -Path $item -Recurse -Force -Verbose
}
 
 
