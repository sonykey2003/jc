###################################################################
#  Version:        1.2
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
    [ValidateSet("HP", "Canon", "Brother")]
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
    InstallDriver([string]$dn){
        try {
            $path = Get-ChildItem $this.drvlink | Where-Object {$_.Mode -eq "d-----"}
            foreach ($p in $path.fullname){

                # installing drivers from inf
                Write-Host "Adding drivers from $p"
                pnputil.exe -i -a ($p+"\*.inf")

               
                Write-Host "Adding Drive to repo..."
                Add-PrinterDriver -Name $dn -erroraction SilentlyContinue  -verbose # HP driver name 
    
            }
                       
        }
        catch{
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
           
        }
    }
    ## add install printer method
    InstallPrinter([int]$port,[string]$dn){
        $port = 9100
        try{
            # Check if the printerport already added
            $existPort = Get-PrinterPort -name $this.PrinterName -erroraction SilentlyContinue
            if ($null -eq $existPort){
                Write-Host "Adding Printer Port $port for $($this.printername)..."
                Add-PrinterPort -name $this.PrinterName -PrinterHostAddress $this.IP -PortNumber $port -erroraction Stop -verbose     
            }
            else {
                Write-Host "Port:$port exists with name: $($this.printername)..."
            
            }
           
            Write-Host "Adding Printer $($this.printername)...hang on tight!"
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


