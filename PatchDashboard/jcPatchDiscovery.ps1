# Github cred
$GHUsername = ''
$GHToken = '' # https://github.com/settings/tokens needs token to write/create repo
$GHRepoName = '' # create a private repo first on Github and paste the name here 
$password = ConvertTo-SecureString "$GHToken" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($GHUsername, $password)

# Environment Setup
$windowstemp = [System.Environment]::GetEnvironmentVariable('TEMP', 'Machine')
$newjsonoutputdir = $windowstemp + '\' + $env:COMPUTERNAME + '.json'
$workingdir = $windowstemp + '\patch-discovery'
$discoverycsvlocation = $workingdir + '\jcPatchDiscovery.csv'
$na = 'n.a.'
$now = get-date -Format "M/dd/yyyy HH:MM:ss tt" 


# Turnnning off the telemtry
Set-GitHubConfiguration -DisableTelemetry -SuppressTelemetryReminder 

# Installing the dependencies 
$pswhModules = 'PowerShellForGitHub','PSWindowsUpdate' # Modules
$pkgs = 'NuGet' # Packages

foreach($p in $pkgs){
    if ($null -eq ( Get-PackageProvider -Name $p -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name $p -Force
    }
    
}

foreach ($module in $pswhModules){
    if ($null -eq (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
        Install-Module $module -Force
    }

}

# Auth to github
Set-GitHubAuthentication -Credential $cred # turnnning off the telemtry

# Getting the missing patches
$missingPatches =  Get-WindowsUpdate
$missingPatchesOut = @()
<# 
Full definition - https://gist.github.com/cfebs/c9d83c2480a716f6d8571fb6cc80fd59
Updates: General updates that may include new features, improvements, and non-critical bug fixes.
Security Updates: Updates specifically aimed at fixing vulnerabilities and improving the overall security of the system.
Critical Updates: High-priority updates that address serious issues, often related to security, stability, or data loss prevention.
Feature Packs: Collections of new features and functionality for the operating system or a specific component.
Service Packs: Cumulative packages of all the updates, fixes, and enhancements released up to a certain point, usually aimed at improving system stability and performance.
Drivers: Updates for hardware drivers to improve compatibility, performance, or to fix issues.
Tools: Utilities and applications provided by Microsoft to help manage, diagnose, or maintain the system.
Optional Updates: Updates that are not critical but may provide improvements or additional features for specific users.

alternatively use this parameter
 -RootCategories <string[]>
        Post search criteria. Finds updates that contain a specified root category name 'Critical Updates', 'Definition Updates', 'Drivers', 'Feature
        Packs', 'Security Updates', 'Service Packs', 'Tools', 'Update Rollups', 'Updates', 'Upgrades', 'Microsoft'.
#>

# in case the machine is fully patched

if ($null -ne $missingPatches){
    
    foreach ($patch in $missingPatches){
        $missingPatchesOut += New-Object -TypeName PSObject -Property @{
            ComputerName = $patch.ComputerName
            Size = $patch.Size
            Category = ($patch.Categories[0] | select name).name
            KB = $patch.KB
            Title = $patch.Title
            WhenAvaliable = $patch.LastDeploymentChangeTime
            IsPresent = $patch.IsPresent
            RebootRequired = $patch.RebootRequired
            checkInTimeStamp = $now
        }
    }
}
else {
    $missingPatchesOut = New-Object -TypeName PSObject -Property @{
            ComputerName = $env:COMPUTERNAME
            Size = $na
            Category = $na
            KB = $na
            Title = $na
            WhenAvaliable = $na
            IsPresent = $na
            RebootRequired = $na
            checkInTimeStamp = $now
        
        }
}
$missingPatchesOut | ConvertTo-Json -Compress |out-file $newjsonoutputdir #-Encoding unicode

# Upload latest JSON to repo
$missingPatchesJSON = (get-content -Path $newjsonoutputdir)
Set-GitHubContent -OwnerName $GHUsername  -RepositoryName $GHRepoName -BranchName 'main' -Path ($env:COMPUTERNAME + '.json') -CommitMessage $env:COMPUTERNAME -Content $missingPatchesJSON

# downloading the existing json files
$GHJsonFiles = (Get-GitHubContent -OwnerName $GHUsername -RepositoryName $GHRepoName -BranchName 'main' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).Entries`
     | Where-Object { $_.name -match '.json' }`
     | Select-Object name, download_url

foreach ($file in $GHJsonFiles) {
    New-Item -ItemType Directory -Force -Path $workingdir | Out-Null
    $dlname = ($workingdir + '\' + $file.name)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $file.download_url -OutFile $dlname
}

# Collate into single csv file
$combinedjson = @()
$jsonfiles = Get-ChildItem -Filter *.json -Path $workingdir
Foreach ($File in $jsonfiles) {
    # $combinedjson += Get-Content -Raw $File.FullName -Encoding unicode | ConvertFrom-Json
    $combinedjson += Get-Content -Raw $File.FullName | ConvertFrom-Json
}
$combinedjson | ConvertTo-Csv -NoTypeInformation | Out-File $discoverycsvlocation
# upload the csv to github
$discoverycsvContent = (get-content -Path $discoverycsvlocation -Raw)
Set-GitHubContent -OwnerName $GHUsername -RepositoryName $GHRepoName -BranchName 'main' -Path "jcPatchDiscovery.csv" -CommitMessage "CSV Upload" -Content $discoverycsvContent

# cleaning up the old records
Set-Location $workingdir
Remove-Item -Recurse *
Remove-Item $newjsonoutputdir -Force