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
            $path = Get-ChildItem $this.drvlink | Where-Object {$_.Mode -eq "d-----"}
            foreach ($p in $path.fullname){

                # doesnt work win11
                Write-Output "Adding drivers from $p"
                pnputil.exe -i -a ($p+"\*.inf")
            }
                       
        }
        catch{
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
           
        }
    }
    ## add install printer method
    InstallPrinter([int]$port = 9100){
        try{
            $dn = ""
            # Determine the driver name 
            switch ($this.drivername) {
                "HP" { $dn = "HP Universal Printing PCL 6" }
                "Canon" { $dn  = "Canon Generic Plus PCL6" }
                "Brother" { $dn  = "Brother Mono Universal Printer (PCL)" }
            }
            # doesnt work win11
            # to add error handling
            Write-Output "Adding Drive to repo..."
            Add-PrinterDriver -Name $dn -erroraction Stop  -verbose # HP driver name 
    
            Write-Output "Adding Printer Port $port for $($this.printername)..."
            Add-PrinterPort -name $this.PrinterName -PrinterHostAddress $this.IP -PortNumber $port -erroraction Stop -verbose 
    
            Write-Output "Adding Printer $($this.printername)...hangon tight!"
            Add-Printer -DriverName $dn -name $this.PrinterName -PortName $this.PrinterName -erroraction Stop -verbose 
            
        }
        catch{
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
           
        }
       
    }

}

function Get-PrinterDriverFromURL {
    param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({$_.Contains(".zip")})]
        [string]$url,

        [Parameter(Mandatory=$True)]
        [string]$FileName,
        #[bool]$cleanup = $True,
        [string]$downloadPath = "c:\windows\temp\"
    )
    if ($FileName -notlike "*.zip"){
        $FileName = $FileName + ".zip"
    }
    try {
        # Driver zip path
        $zip = $downloadPath+$FileName

        # Unzipping driver path
        $unzipPath = $zip.Trim('.zip')

        # Downloading driver zip from url
        Invoke-WebRequest -Uri $url -OutFile $zip -ErrorAction Stop -Verbose

        # Unzip the downloaded file
        Expand-Archive -Path $zip -DestinationPath $downloadPath -Force -Verbose
                  
        return $unzipPath
    }   
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
       
    }
   
}


