# Required module: Jumpcloud PWSH
# Connecting to JC online

$JCAPIKEY = ""
$JCorgID = ""

# API auth header
$headers = @{   
    "x-org-id" = $JCorgID #your org id
    "x-api-key" = $JCAPIKEY #your admin api key
    "content-type" = "application/json"
}

$baseUrl = "https://console.jumpcloud.com/api/v2/softwareapps/"
# Retry the install basically use it as a way to enforce the app updates for VPPs - VPPs only

function getSoftwareAppAssociations{
    # Getting the system associations from an app
    param (
        [Parameter(Mandatory=$false)]
        [string]$softwareAppID
    )

    $getAssoUrl = $baseUrl + $softwareAppID + '/associations?targets=system'
    $response =  Invoke-RestMethod -Uri $getAssoUrl -Method Get -Headers $headers  -ErrorAction SilentlyContinue
    return $response.to.id
}


function getSoftwareApp {
   # Pagination, in case the there are more than 100 apps in total
    $limit = 100
    $skip = 0
    $hasMore = $true
    $AppsResponse = @()
    while ($hasMore) {
        $uri = $AppUrl+"?limit=$limit&skip=$skip"

        # Call the API
        $AppsResponse += Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

        # Check if there are more records to fetch
        if ($AppsResponse.Count -lt $limit) {
            $hasMore = $false
        } else {
            $skip += $limit
        }
    }

    return $AppsResponse | where {$_.settings.packageManager -eq 'APPLE_VPP'} #focus only on VPP here.
}
function retryInstallation {
    param(
         # Parameter help description
        [Parameter(Mandatory=$false)]
        [array]$softwareAppID,

        
        [Parameter(Mandatory=$false)] 
        [bool]$all = $false # fetch all VPPs if explictly needed

    )

    if ($all){
        #Write-Output "All selected will go through all VPPs in this ORG"
        $softwareAppID = getSoftwareApp
       
    }

    foreach ($App in $softwareAppID){
        if ($all){
            $AppID= $app.id
            $AppDN = $app.displayName
        }
        else{
            $AppID = $app
            $AppDN = $app
        }

        # fetching the asscociated system IDs for retrying
        $systemID = getSoftwareAppAssociations -softwareAppID $AppID
        if ($null -ne $systemID){
            $systemIDJoined = $systemID -join ', '
            $retryUrl = $baseUrl+ $AppID + '/retry-installation'
            $body = @{
                "system_ids" = @(
                    $systemIDJoined
                )
        
            } | ConvertTo-Json
        
            # Using invoke-webrequest instead in order to capture the response code, expecting 204
            $retryResponse =  Invoke-WebRequest -Uri $retryUrl -Method Post -Headers $headers -Body $body 
            if ($retryResponse.StatusCode -eq 204){
                Write-host "Retry installation triggered successfully for app $AppDN" -ForegroundColor Green
            }
            else {
                Write-host "Erorr: $($retryResponse.StatusCode), $($retryResponse.StatusDescription) for app $AppDN" -ForegroundColor Red
            }
        }
        else {
           Write-Output "$AppDN, ID:$appID is NOT bind to any system, skipping!"

        }
        
    }
   
 }
 
# Example use cases 
# Use this to trigger a retry installation to all VPPs in your ORG"
retryInstallation -all:$true

# This will trigger a retry installation on all systems bind to a specific app
retryInstallation -softwareAppID "softwareApp_ID" # You can get the ID from get-jcsdkSoftwareApp 