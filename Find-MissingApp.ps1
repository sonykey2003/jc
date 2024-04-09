
# -----------------------------------------------------------------------------
# Script: Find-MissingApp.ps1
# Version: 2.0.1
# Author: Shawn Song
# Reference: 
#  -  https://community.jumpcloud.com/t5/community-scripts/is-your-sso-feeling-lonely-identifying-unused-sso-applications/m-p/4239#M400
# 
# Notes: Identifying if the device is missing the desired app, scan though all your systems except the mobile devices, output a CSV of these systems. 
# Requirements:
# - The latest JumpCloud PowerShell Module. https://jumpcloud.com/support/install-the-jumpcloud-powershell-module
# - PowerShell 7 and above versions. 
# -----------------------------------------------------------------------------


$MissingApp = Read-Host "Input the name of the app" # Given a name of the app you want to find if it's missing on the devices.
$DesiredApp = '*'+$MissingApp+'*'
$systemsMissingApp = @()
$date = (Get-Date).ToString('MMddyyyy')

# Ruling out the mobile devices
$filters = @'
    filter[0]=os:$ne:iOS&filter[1]=os:$ne:Android&filter[2]=os:$ne:iPadOS&filter[3]=os:$ne:iOS
'@
$allsystems = Get-JcSdkSystem -Filter $filters 

foreach ($system in $allsystems){
    $notMissing = 0

    $allprograms = Get-JCSystemApp -SystemID $system.id -ErrorAction SilentlyContinue

    foreach ($program in $allprograms){
        if ($program.name -like $DesiredApp){
            $notMissing += 1
        }
        
    }
    if ($notMissing -eq 0) {
        $systemsMissingApp += $system
        
    }
}

$systemsMissingApp | select hostname,displayName,os,version,ID | Export-Csv @("Missing$DesiredApp_$date.csv")
