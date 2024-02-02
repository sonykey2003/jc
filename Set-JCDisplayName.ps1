
# -----------------------------------------------------------------------------
# Script: Set-JCDisplayName.ps1
# Version: 1.0.0
# Author: Shawn Song
# Reference: 
#  -  https://community.jumpcloud.com/t5/community-scripts/powershell-add-the-systems-to-a-system-group-depends-on-where/m-p/1733#M172
# 
# Notes: Don't run this on all devices unless you are 100% sure about the impact!!
# Requirements:
# - The latest JumpCloud PowerShell Module. https://jumpcloud.com/support/install-the-jumpcloud-powershell-module
# - PowerShell 7 and above versions. 
# - JumpCloud API keys for both Manager & Read-only roles. 
# -----------------------------------------------------------------------------


# Connect to your JC Tenant - Manager role is good enough!
Connect-JCOnline -JumpCloudApiKey $env:JCRW # Strongly suggest storing the API key in the system env variable,

$jcSystems = "system_ID01","system_ID02"

# Don't run this on all devices unless you are 100% sure about the impact!!
#$jcSystems  = (Get-JCSystem -returnProperties osFamily | where {($_.osFamily -ne "ios") -and ($_.osFamily -ne "android")})._id # ruling out the mobile devices

# Determine the machine type
function Get-MachineType {
    param (
        [parameter(Mandatory=$true)]    
        [string]$systemID
    )
    $hasBattery = Get-JCSystemInsights -Table Battery -SystemId $systemID
    $type = "LT"

    if ($null -eq $hasBattery ) {
       $type = "DT"
    }
   return $type
}

# Get the SN (and cap at 10 char) as part of the hostname
function Get-MachineSN{
    param (
        [Int32]$snCharLimit = 12, # 12 is the hostname hard limit for Windows
        
        [parameter(Mandatory=$true)]    
        [string]$systemID
    )
    $SN = (Get-JCSystemInsights -Table SystemInfo -id $systemID | select HardwareSerial).HardwareSerial
   
    if (($SN.Length -gt $snCharLimit) -and ($null -ne $SN)){
        $SN = $SN.trim() -replace " ",'' -replace '-','' -replace '\r?\n\z'  # removing whitespaces
        $SN = $SN.Substring(0,$snCharLimit)
    }
    
    return $SN
}

# Create a new device group to gather these systems together
$newGrounName = "NewHostName"
$ng = Get-JCGroup -Type System -name $newGrounName -ErrorAction SilentlyContinue
if ($null -eq $ng){
    $ng = New-JCSystemGroup -GroupName "NewHostName"
}

# Executing the change
foreach ($s in $jcSystems){
    $displayName =  (Get-MachineType -systemID $s) +'-' + (Get-MachineSN -systemID $s)
    
    # Changing the displayname on JC
    Write-Host "new name for $s will change to: $displayname"
    Set-JCSystem -displayName $displayName

    # Add to the system group
    write-host "adding $displayname to group $($ng.name)"
    Add-JCSystemGroupMember -GroupID $ng.id -SystemID $s

}


