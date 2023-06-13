# Required module: Jumpcloud PWSH
# Connecting to JC online
$JCAPIKEY = "773254dfedd8d4286c05172e12136cf00ff74b21"
$JCorgID = "615d55c193cd2850187c6ff5"

# API auth header
$headers = @{
    "x-org-id" = $JCorgID #your org id
    "x-api-key" = $JCAPIKEY #your admin api key
    "content-type" = "application/json"
}


$AppUrl = "https://console.jumpcloud.com/api/v2/softwareapps"

# Pagination
$limit = 100
$skip = 0
$hasMore = $true
$AppleAppsResponse = @()
while ($hasMore) {
    $uri = $AppUrl+"?limit=$limit&skip=$skip"

    # Call the API
    $AppleAppsResponse += Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    # Check if there are more records to fetch
    if ($AppleAppsResponse.Count -lt $limit) {
        $hasMore = $false
    } else {
        $skip += $limit
    }
}

# Set the VPP to auto update
foreach ($app in $AppleAppsResponse){

    $pkgMgr = $app.settings.packageManager 
    $autoUpdate = $app.settings.autoUpdate
    $trueValue = "True"

    if (($pkgMgr -eq "APPLE_VPP") -and ($autoUpdate -eq $false)) {
        Write-Host "$($app.displayname) is NOT auto updating, setting to AutoUpdate..."
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


    }
}