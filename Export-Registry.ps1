 # Export-Registry.ps1
 #requires -version 2.0

# -----------------------------------------------------------------------------
# Script: Export-Registry.ps1
# Author: Jeffery Hicks - Forked by Shawn Song
# Original Repo: https://github.com/PsCustomObject/PowerShell-Functions/blob/master/Export-Registry.ps1
# Notes: Added a recursive function to capture the keys with nested under an paren key with empty value.
# -----------------------------------------------------------------------------

Function Export-Registry {

    <#
       .Synopsis
        Export registry item properties.
        .Description
        Export item properties for a give registry key. The default is to write results to the pipeline
        but you can export to either a CSV or XML file. Use -NoBinary to omit any binary registry values.
        .Parameter Path
        The path to the registry key to export.
        .Parameter ExportType
        The type of export, either CSV or XML.
        .Parameter ExportPath
        The filename for the export file.
        .Parameter NoBinary
        Do not export any binary registry values
       .Example
        PS C:\> Export-Registry "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -ExportType xml -exportpath c:\files\WinLogon.xml
        
        .Example
        PS C:\> "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MobileOptionPack","HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft SQL Server 10" | export-registry
      
        .Example
        PS C:\> dir hklm:\software\microsoft\windows\currentversion\uninstall | export-registry -ExportType Csv -ExportPath "C:\work\uninstall.csv" -NoBinary
        
       .Notes
        NAME: Export-Registry
        VERSION: 1.0
        AUTHOR: Jeffery Hicks
        LASTEDIT: 10/14/2010 
        
        Learn more with a copy of Windows PowerShell 2.0: TFM (SAPIEN Press 2010)
        
       .Link
        Http://jdhitsolutions.com/blog
        
        .Link
        Get-ItemProperty
        Export-CSV
        Export-CliXML
        
       .Inputs
        [string[]]
       .Outputs
        [object]
    #>
    
    [cmdletBinding()]
    
    Param(
    [Parameter(Position=0,Mandatory=$True,
    HelpMessage="Enter a registry path using the PSDrive format.",
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [ValidateScript({(Test-Path $_) -AND ((Get-Item $_).PSProvider.Name -match "Registry")})]
    [Alias("PSPath")]
    [string[]]$Path,
    
    [Parameter()]
    [ValidateSet("csv","xml")]
    [string]$ExportType,
    
    [Parameter()]
    [string]$ExportPath,
    
    [switch]$NoBinary
    
    )
    
    Begin {
        Write-Verbose -Message "$(Get-Date) Starting $($myinvocation.mycommand)"
        #initialize an array to hold the results
        $data=@()
     } #close Begin
    
    Process {
        #go through each pipelined path
        $hiveKeys = (Get-ChildItem -Recurse -Path $path | select pspath).pspath
    
        Foreach ($item in $hiveKeys) {
            Write-Verbose "Exporting non binary properties from $item"
            #get property names
            $item = $item.Replace("Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE","HKLM:")
            $properties= Get-ItemProperty -path $item | 
            #exclude the PS properties
             Select * -Exclude PS*Path,PSChildName,PSDrive,PSProvider |
             Get-Member -MemberType NoteProperty,Property -erroraction "SilentlyContinue"
            if ($NoBinary)
            {
                #filter out binary items
                Write-Verbose "Filtering out binary properties"
                $properties=$properties | Where {$_.definition -notmatch "byte"}
            }
            Write-Verbose "Retrieved $(($properties | measure-object).count) properties"
            #enumrate each property getting itsname,value and type
            foreach ($property in $properties) {
                Write-Verbose "Exporting $property"
                $value=(get-itemproperty -path $item -name $property.name).$($property.name)
                
                if (-not ($properties))
                {
                    #no item properties were found so create a default entry
                    $value=$Null
                    $PropertyItem="(Default)"
                    $RegType="System.String"
                }
                else
                {
                    #get the registry value type
                    $regType=$property.Definition.Split()[0]
                    $PropertyItem=$property.name
                }
                #create a custom object for each entry and add it the temporary array
                $data+=New-Object -TypeName PSObject -Property @{
                    "Path"=$item
                    "Name"=$propertyItem
                    "Value"=$value
                    "Type"=$regType
                }
            } #foreach $property
        }#close Foreach 
     } #close process
    
    End {
      #make sure we got something back
      if ($data)
      {
        #export to a file both a type and path were specified
        if ($ExportType -AND $ExportPath)
        {
          Write-Verbose "Exporting $ExportType data to $ExportPath"
          Switch ($exportType) {
            "csv" { $data | Export-CSV -Path $ExportPath -noTypeInformation }
            "xml" { $data | Export-CLIXML -Path $ExportPath }
          } #switch
        } #if $exportType
        elseif ( ($ExportType -AND (-not $ExportPath)) -OR ($ExportPath -AND (-not $ExportType)) )
        {
            Write-Warning "You forgot to specify both an export type and file."
        }
        else 
        {
            #write data to the pipeline
            $data 
        }  
       } #if $#data
       else 
       {
            Write-Verbose "No data found"
            Write "No data found"
       }
         #exit the function
         Write-Verbose -Message "$(Get-Date) Ending $($myinvocation.mycommand)"
     } #close End
    
    } #end Function
    
    