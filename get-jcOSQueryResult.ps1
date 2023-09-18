
# -----------------------------------------------------------------------------
# Script: get-jcOSQueryResult.ps1
# Version: 1.0.3
# Author: Shawn Song
# Reference: 
#  -  https://github.com/TheJumpCloud/jcapi-powershell/blob/master/SDKs/PowerShell/JumpCloud.SDK.V1/examples/Search-JcSdkCommandResult.md
# 
# Notes: Always name your cmd with a proper naming covention.
# Requirements:
# - The latest JumpCloud PowerShell Module.
# - PowerShell 7 and above versions. 
# -----------------------------------------------------------------------------

# Input the cmd name you use for querying the Edge/Firefox add-ons
$cmdName = "Edge Extensions - JCQSQuery" # Microsft Edge Browser 
#$cmdName = "FF Add-ons - JCQSQuery" # Firefox Browser
Connect-JCOnline -JumpCloudApiKey "your-read-only-api-key" # Read-only permission is all you need!

#################################### Don't Change the code below this line ####################################
function get-jcOSQueryResults {
    param (
        [string]$cmdName
    )
    $commandsResultBody = @{
        filter = @{
            'and' = @("name:`$eq:$cmdName" )
        }
        fields = 'response.data.exitCode response.data.output system responseTime'
    }| ConvertTo-Json -Depth 99
    $results = Search-JcSdkCommandResult -body $commandsResultBody 
    return $results
}

function outputOSQReport {
    # Build the array for outputting to csv
    $outPutResults = @()

    # Getting the cmd results with the json output
    $results = get-jcOSQueryResults($cmdName)

    # Getting the extension info from each cmd result
    foreach ($r in $results){
        $ext = $r.DataOutput | ConvertFrom-Json -Depth 99 
        foreach ($e in $ext){
            $tempOutput = "" | select dataCollectTime,name,author,identifier,install_time,manifest_hash,path,permissions,profile,profile_path,version,systemID
            
            $tempOutput.dataCollectTime = $r.responseTime
            $tempOutput.name = $e.name
            $tempOutput.author = $e.author
            $tempOutput.identifier = $e.identifier
            $tempOutput.install_time  = $e.install_time
            $tempOutput.manifest_hash = $e.manifest_hash
            $tempOutput.path = $e.path
            $tempOutput.permissions = $e.permissions
            $tempOutput.profile = $e.profile
            $tempOutput.profile_path = $e.profile_path
            $tempOutput.version = $e.version
            $tempOutput.systemID = $r.systemId
            $outPutResults += $tempOutput
        }
    }
    $outPutResults | Export-Csv ".\$((Get-Date).ToString("yyyyMMdd"))_ExtReport.csv"
    
}

outputOSQReport