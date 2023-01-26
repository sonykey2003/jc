
# -----------------------------------------------------------------------------
# Script: DOConfig.ps1
# Version: 1.0.1
# Author: Shawn Song
# Reference: https://learn.microsoft.com/en-us/windows/win32/dmwmibridgeprov/mdm-bridge-wmi-provider-portal
# Notes: this script only works under localsystem account, suggested to run in JumpCloud's cmd or using psexec.
# -----------------------------------------------------------------------------

# Configuring Delivery Optimisation settings
$classname = "MDM_Policy_Config01_DeliveryOptimization02"
$PRclassname = "MDM_Policy_Result01_DeliveryOptimization02"
$namespace = "root\cimv2\mdm\dmmap" 
$classProperties = (Get-CimClass -Namespace $namespace -ClassName $classname | select CimClassProperties).cimclassproperties
$groupGuid = "fde820f5-362c-4eb3-b7fa-0b961b40ff32" #Generate by ([guid]::NewGuid()).guid for a GUID based Group ID

# Hardcoding the InstanceID & ParentID for the new CIM instance
$obj = @{
    instanceID="DeliveryOptimization"
    ParentID="./Vendor/MSFT/Policy/Config"

}

$session = Get-CimInstance -namespace $namespace -ClassName $classname

if ($null -eq $session){
    #creating cim instance if it's not there
    $session = New-CimInstance -Namespace $namespace -ClassName $classname -Property $obj
}

# Populating the policy result (existing settings) into an variable
$orginalProp = Get-CimInstance -Namespace $namespace -ClassName $prclassname

foreach ($propName in $classProperties.name){

    # Building the CIM instance based on the attributes collected from the policy result
   if ($propName-ne "instanceID" -and $propName -ne "ParentID"){
        $obj.add($propName,$orginalProp.$propname)
   }
   
}

# Print out the existing settings
Write-Host "this is the orginal setting"
$session

# Making the changes

#Test case 1:
#https://learn.microsoft.com/en-us/windows/deployment/do/delivery-optimization-test
$session.DODownloadMode = 2
$session.DOGroupID = $groupGuid
$session.DOAbsoluteMaxCacheSize = 10000
$session.DOMonthlyUploadDataCap = 10000

# Print out the settings will be applied
Write-Host "this is the modified setting"
$session

# Apply the changes
Set-CimInstance -CimInstance $session -verbose

# Cleaning up
#Write-Host "`n Done, cleaning up..."
#remove-ciminstance -CimInstance $session -verbose