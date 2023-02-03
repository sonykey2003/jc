# Install Printers Remotely with JumpCloud Command
And in the background - no user interactions are needed.

### What It Does

* Function `Get-PrinterDriverFromURL` will download and unzip the curated printer drivers from a public link (i.e. the ones in my repo).
  * Only the universal drivers for the brands below are supported at the moment:
    * `HP`
    * `Canon`
    * `Brother` 
* You can create printer objects as many as needed, like:
```pwsh
## HP Printer 01
$HPurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/hp.zip"
$ReDriverPathHP = Get-PrinterDriverFromURL -url $HPurl -FileName "HP"
$HP_Prn01 = "HP01" # Name your printer as you wish
$Prns += [Printer]::new($HP_Prn01,"your_printer_ip","HP","your_country_code",$ReDriverPathHP)

...

## HP Printer 05
$HPurl = "https://raw.githubusercontent.com/sonykey2003/jc/main/printerCMD/universalDrivers/hp.zip"
$ReDriverPathHP = Get-PrinterDriverFromURL -url $HPurl -FileName "HP"
$HP_Prn05 = "HP05" # Name your printer as you wish
$Prns += [Printer]::new($HP_Prn05,"your_printer_ip","HP","your_country_code",$ReDriverPathHP)

```
* OR in combination with other 2 brands. 


### How to Use It
* Create a Jumpcloud CMD.
* Select `Windows`, `Powershell`.
* Fork the `# Building the Printer Parameters` section in `cmdTemplate.ps1`, paste it in the command body. 
* Set the `Timeout` to 2000 seconds.
* Upload `MasterPrnRepo.psm1` to the command, make sure the path is `C:\Windows\Temp\MasterPrnRepo.psm1`
* Bind the cmd to a (group of) device and run it!