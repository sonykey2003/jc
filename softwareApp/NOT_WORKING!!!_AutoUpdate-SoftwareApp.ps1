##########################################################################################
# DO NOT use this script - it won't work!!!
##########################################################################################


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




# You can enforce the auto update for android & windows apps too
#$appPkgMgr = "CHOCOLATEY"  # Windows apps
#$appPkgMgr = "GOOGLE_ANDROID" 
$appPkgMgr = "APPLE_VPP"

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
 
     return $AppsResponse | where {$_.settings.packageManager -eq $appPkgMgr} 
 }


# Set the VPP to auto update
foreach ($app in $AppsResponse){
  
    
    $pkgMgr = $app.settings.packageManager 
    $autoUpdate = $app.settings.autoUpdate

    if (($pkgMgr -eq $appPkgMgr) -and ($autoUpdate -eq $false)) {
        Write-Host "$($app.displayname) is NOT auto updating, fixing..."
        $appUpdateUrl = $AppUrl + "/" + $app.id
        $body = @{
            "displayName" = $app.displayName
            "settings" = @(
                @{
                    "autoUpdate" = $true
                }
            )
        }
        $body = $body | ConvertTo-Json

        $updateResponse =  Invoke-RestMethod -Uri $appUpdateUrl -Method Put -Headers $headers -Body $body 
        Write-Host "$($updateResponse.displayname) $($updateResponse.id) has set to $($updateResponse.settings.autoUpdate)" -ForegroundColor Green

        # Optional to retry the install basically a way to enforce the app updates for VPPs - suggest to do on VPP only

    }
}