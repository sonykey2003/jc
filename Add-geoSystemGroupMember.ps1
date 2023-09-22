
# -----------------------------------------------------------------------------
# Script: Add-geoSystemGroupMember.ps1
# Version: 1.0.1
# Author: Shawn Song
# Reference: 
#  -  https://community.jumpcloud.com/t5/community-scripts/powershell-add-the-systems-to-a-system-group-depends-on-where/m-p/1733#M172
# 
# Notes: Run this script regularly if you wanted to keep moving the device around the geo based groups, not more than twice a day!
# Requirements:
# - The latest JumpCloud PowerShell Module. https://jumpcloud.com/support/install-the-jumpcloud-powershell-module
# - PowerShell 7 and above versions. 
# -----------------------------------------------------------------------------

# Connect to JC online
Connect-JCOnline -JumpCloudApiKey "Your-JC-manager-api-key" #JumpCloud manager admin role is sufficient. 

# a function to query the geo info from an IP supplied
function Get-IPGeolocation {
    Param
    (
      [string]$IPAddress
    )
   
    $request = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPAddress"
   
    [PSCustomObject]@{
      IP      = $request.query
      City    = $request.city
      Country = $request.country
      Isp     = $request.isp
    }
  }


# Getting the systems are online with an public IP (excluding the mobile devices).
$jcsystemInfo = Get-JCSystem | where {($_.active -eq $true) -and ($null -ne $_.remoteIP)}
$jcsysgroups = Get-JCGroup -Type System


# Adding the systems to these geo related groups
if ($null -ne $jcsystemInfo){
    foreach ($system in $jcsystemInfo){

        # Moving the system off from the previous system groups - dynamic groups will not be affected
        $jcsysgroups | Get-JCSystemGroupMember | where {$_.systemid -eq $system.id} | Remove-JCSystemGroupMember -SystemID $system.id

        # Now after cleaning up, adding to the new groups based on the device current location
        $geolocation = Get-IPGeolocation -IPAddress $system.remoteIP
    
        $targetGroup = $geolocation.Country.Replace(' ','') + "_" + $system.osFamily
        
        # Adding the system to the target group
        $testGroup = Get-JCGroup -Type System -Name $targetGroup -ErrorAction SilentlyContinue
        $testMember = Get-JCSystemGroupMember -GroupName $targetGroup -ErrorAction SilentlyContinue | where system -eq $system.displayName
    
        if ($null -eq $testGroup){
            $newGroup = New-JCSystemGroup -GroupName $targetGroup
            Add-JCSystemGroupMember -GroupID $newGroup.id -SystemID $system._id 
            Write-Output "$($system.displayname) has been added to $($newgroup.name) system group! `n "
    
        }
        elseif ($null -ne $testGroup -and $null -eq $testMember) {
            Add-JCSystemGroupMember -GroupID $testGroup.id -SystemID $system._id
            Write-Output "$($system.displayname) has been added to $($testGroup.name) system group! `n "
        }
        else {
            Write-Output "$($system.displayname) already exists in $($testGroup.name) system group! `n "
        }
    }
}
else {
    Write-Output "Phew! No system needs to be moved, take a day off!"
}