
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
$filters = @('os:$ne:iOS','os:$ne:Android','os:$ne:iPadOS')
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

$reportName = "Missing_" +  $MissingApp + "_" + $date + ".csv"

Write-Host "Here is the glance of the report:"
$systemsMissingApp | select hostname,displayName,os,version,ID  -first 10 | ft
Write-Host "The full report has been exported to $reportname"
$systemsMissingApp | select hostname,displayName,os,version,ID | Export-Csv $reportName
