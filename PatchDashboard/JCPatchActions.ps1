# -----------------------------------------------------------------------------
# Script: JCPatchActions.ps1
# Version: 1.0.1
# Author: Shawn Song
# Requirement to run this: 
#  - Powershell 7+
#  - Jumpcloud powershell module
#  - OS: MacOS, Windows, Linux
# -----------------------------------------------------------------------------

# Use your writable API key - suggested JC manager role. 
## Learn more about the admin roles https://jumpcloud.com/support/admin-portal-roles

# Getting the key elements together
$apiKey = '' # Your JC manager admin API key
Connect-JCOnline -JumpCloudApiKey $apiKey
$outdatedSystems = Import-csv "/the-path-to/outdatedSystems-2023-08-14.csv" # The CSV exported from Patch Dashboard step 2

# Create or provide the most agressive patch policy IDs for respective OSes
$winPolicyID = 'winPolicyID'
$macPolicyID = 'macPolicyID'
$linuxPolicyID = 'linuxPolicyID'

$enforcePatchPolicies = @(
    [PSCustomObject]@{
        Name = 'winPolicyID'
        ID = $winPolicyID
    },
    [PSCustomObject]@{
        Name = 'macPolicyID'
        ID = $macPolicyID
    },
    [PSCustomObject]@{
        Name = 'linuxPolicyID'
        ID = $linuxPolicyID

    }

)

# Create a remediation group with timestamp 
$remdyGroupName = "PatchRemedy_"+((get-date).ToString("yyyy-MM-dd"))
$newGroup = New-JCSystemGroup -GroupName $remdyGroupName -ErrorAction SilentlyContinue
if ($null -eq $newGroup.id){
    $newGroup.id = (Get-JCGroup -Type System -Name $remdyGroupName).id
}

# Adding the outdated system to the remediation group
function addAssocToGroup {
    param (
        
        [Parameter(Mandatory=$True)]
        [ArgumentCompleter({
            $type = @('systems','policies')
            return $type | Where-Object { $_ -like "$wordToComplete*" } | ForEach {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        })]
        [string]$type,

        [Parameter(Mandatory=$false)]
        [string]$groupID,
        
        [PSCustomObject[]]$arrayOfStuff
    )
    
    if ($type -eq 'systems'){
        foreach ($system in $arrayOfStuff){
            try {
                Add-JCSystemGroupMember -GroupName $newGroup.Name -GroupID $groupID -SystemID $system.systemID -ErrorAction Continue
                Write-Host "Adding $($system.DisplayName) to $($newGroup.Name)..."
            }
            catch {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        }
    }
    else {
        foreach ($policy in $arrayOfStuff){
            try {
                Add-JCAssociation -Type policy -Id $policy.id -TargetType system_group -TargetId $groupID -Force -ErrorAction Continue
                Write-Host "Adding $($policy.name):$($policy.ID) to $($newGroup.Name)..."
            }
            catch {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
   
}

# Binding the outdated systems to the enforcement patch policies
$groupID = $newGroup.id

addAssocToGroup -type systems -arrayOfStuff $outdatedSystems -groupID $groupID 
addAssocToGroup -type policies -arrayOfStuff $enforcePatchPolicies -groupID $groupID 

