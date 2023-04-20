# Github cred
$GHUsername = 'sonykey2003'
$GHToken = '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' # https://github.com/settings/tokens needs token to write/create repo
$GHRepoName = 'JC-WinPatch-Discovery' # You need to create this repo first on Github
$password = ConvertTo-SecureString "$GHToken" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($GHUsername, $password)


# Environment Setup
$windowstemp = [System.Environment]::GetEnvironmentVariable('TEMP', 'Machine')
$newjsonoutputdir = $windowstemp + '\' + $env:COMPUTERNAME + '.json'
$workingdir = $windowstemp + '\patch-discovery'
$discoverycsvlocation = $workingdir + '\jcPatchDiscovery.csv'

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
Set-GitHubAuthentication -Credential $cred

# Getting the missing patches
$missingPatches =  Get-WindowsUpdate -MicrosoftUpdate # for msft updates only

# Output local JSON
$missingPatches |select ComputerName,Size,KB,Title,LastDeploymentChangeTime,IsPresent,RebootRequired | ConvertTo-Json -Compress | out-file $newjsonoutputdir #-Encoding unicode

# Upload latest JSON to repo
$missingPatchesJSON = (get-content -Path $newjsonoutputdir)
Set-GitHubContent -OwnerName $GHUsername -RepositoryName $GHRepoName -BranchName 'main' -Path ($env:COMPUTERNAME + '.json') -CommitMessage $env:COMPUTERNAME -Content $missingPatchesJSON

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