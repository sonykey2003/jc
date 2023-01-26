###################################################################
#  Version:        1.1
#
#
#  Author:         Shawn Song
#  Creation Date:  25-Jan2023
#  Purpose/Change: Master Printer repo
###################################################################


class Printer
{
    # Printer Properties
    [string]$PrinterName
    [string]$IP

    # Validating the driver name
    [ValidateSet("HP", "Cannon", "Brother")]
    [string]$drivername

    [string]$locale
    [string]$drvlink

    # Optional attributes
    ##[string]$floor
    ##[string]$office


    # Constructor
    Printer(
        [string]$PrinterName,
        [string]$IP,
        [string]$drivername,
        [string]$locale,
        [string]$drvlink

        # Optional attributes
        ##[string]$floor,
        ##[string]$office,
    )
    {
        $this.PrinterName = $PrinterName
        $this.IP = $IP
        $this.drivername = $drivername
        $this.locale = $locale
        $this.drvlink = $drvlink

        # Optional attributes
        ##$this.floor = $floor
        ##$this.office = $office
    }

    # Methods
    ## add install printer driver from link method
    InstallDriver(){
        try {
           
            Set-Location $this.drvlink
            pnputil.exe -i -a *.inf
            
        }
        catch [System.Exception] {
            Write-Output $_
        } 
    }
    ## add install printer method
    InstallPrinter([int]$port = 9100){

        $dn = ""
        # Determine the driver name 
        switch ($this.drivername) {
            "HP" { $dn = "HP Universal Printing PCL 6" }
            "Canon" { $dn  = "Canon Generic Plus PCL6" }
            "Brother" { $dn  = "Brother Mono Universal Printer (PCL)" }
        }

        Add-PrinterDriver -Name $dn -erroraction silentlycontinue  -verbose # HP driver name 
        Add-PrinterPort -name $this.PrinterName -PrinterHostAddress $this.IP -PortNumber $port -erroraction silentlycontinue -verbose 
        Add-Printer -DriverName $dn -name $this.PrinterName -PortName $this.PrinterName -erroraction silentlycontinue -verbose 
        
    }

}

function Get-PrinterDriverFromURL {
    param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({$_.Contains(".zip")})]
        [string]$url,

        [Parameter(Mandatory=$True)]
        [string]$FileName,
        [bool]$cleanup = $True,
        [string]$downloadPath = "c:\windows\temp\"
    )
    if ($FileName -notlike "*.zip"){
        $FileName = $FileName + ".zip"
    }
    try {
        $zip = $downloadPath+$FileName
        Invoke-WebRequest -Uri $url -OutFile $zip -ErrorAction Stop

        # Unzip the downloaded file
        Expand-Archive -Path $zip -DestinationPath $downloadPath -Force
        # remove the downloaded zip file after extracting
        
        if ($cleanup) {
            <# Action to perform if the condition is true #>
            Remove-Item -Path $zip -Force
        }
       
    }   
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        # you can also write the error to a log file
        # Add-Content -Path "C:\path\to\logfile.txt" -Value $($_.Exception.Message)
    }
   
}