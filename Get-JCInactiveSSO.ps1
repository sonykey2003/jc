
# -----------------------------------------------------------------------------
# Script: Get-JCInactiveSSO.ps1
# Version: 1.0.1
# Author: Shawn Song
# Reference: 
#  -  https://community.jumpcloud.com/t5/community-scripts/powershell-add-the-systems-to-a-system-group-depends-on-where/m-p/1733#M172
# 
# Notes: Identifying Unused SSO Applications in JumpCloud for the past x days. 
# Requirements:
# - The latest JumpCloud PowerShell Module. https://jumpcloud.com/support/install-the-jumpcloud-powershell-module
# - PowerShell 7 and above versions. 
# -----------------------------------------------------------------------------


$Apps = Get-JcSdkApplication | select DisplayName,displaylabel,name,SsoUrl
$trackingDays = 30
$outCSVreport = @()

foreach ($app in $Apps){
    $report = "" | select AppDN,AppLabel,SSOUrl,Unused,last_5_activities

    $loggedOnEvents = get-jcevent -Service:('sso') -starttime:((get-date).AddDays(-$trackingDays)) `
     -SearchTermAnd @{"application.display_label"=$app.DisplayLabel } -ErrorAction SilentlyContinue
    $report.AppDN = $app.DisplayName
    $report.AppLabel = $app.DisplayLabel
    $report.SSOUrl = $app.SsoUrl

    if ($null -ne $loggedOnEvents) {
        Write-Host "$($app.DisplayName) has $($loggedOnEvents.Count) events in the past $trackingDays days!`n SSO url: $($app.SsoUrl)`n" -ForegroundColor Green
        $report.Unused = $false
        $report.last_5_activities = $loggedOnEvents | Join-String -Separator "`n"
    }
    
    else {
        Write-Host "$($app.DisplayName) is not been accessed in the past $trackingDays days!`n SSO url: $($app.SsoUrl)`n"
        $report.Unused = $true
        $report.last_5_activities = 'N/A'
    }
    $outCSVreport += $report
}
$outCSVreport | Export-Csv InactiveSSO_report.csv

