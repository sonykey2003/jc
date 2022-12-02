##############################################################################################################################
# Authors: Juergen Klaassen & Shawn Song
# Version: 1.1
# Date: 2022-12-01
##############################################################################################################################

##############################################################################################################################
# Config the parameters below #
##############################################################################################################################

# Put in your JC org ID & API Key (Writeable)
$org_id = "<Organization ID>"
$apiKey = "<API Key>"

# Change the policy name and ID accordingly 
$policyID = "<Policy ID>"
$policyName = "<Policy Name>" # e.g. "Advanced: Imported Custom Registry Keys"

# Importing new reg keys from a csv
# You may use this repo to export a reg key hive, recursively:
# https://github.com/sonykey2003/jc/blob/main/Export-Registry.ps1

$csvPath = "<Path to CSV file>" # The path of the exported CSV from a reg key hive.


##############################################################################################################################
# Don't Change below this line! #
##############################################################################################################################


# Getting the existing setings from the policy, if any
$headers = @{
    "x-org-id" = $org_id
    "x-api-key" = $apiKey
    "content-type" = "application/json"
}

$url = "https://console.jumpcloud.com/api/v2/policies/" + $policyID

$importedKeys = Import-Csv $csvPath
$response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
$existingkeys = $response.values.value

# Constructing the body structure, and stitching with the existing values
$body = @{} | select name,values,template
$newvalue = @{} | select value,configFieldID,configFieldName,sensitive
$newkeysOut = @()

foreach ($iKey in $importedKeys){

    # Mapping the key types from the CSV to JC policy console
    switch ($ikey.type) {
        "int" {$type = "DWORD"}
        "uint32"{$type = "DWORD"}
        "string" {$type = "String"}
        "long"{$type = "QWORD"}
        # More to map later
        Default {}
    }

    # Our reg key policy only supports HKLM at the moment:
    #https://support.jumpcloud.com/s/article/Create-Your-Own-Windows-Policy-Using-Registry-Keys

    if ($ikey.Path -contains "HKCU:") {
        Write-Output "$($iKey.path) $($ikey.Name) will not be imported as the policy doesn't support keys in HKCU"
    }
    else {
        $newKey =  [pscustomobject]@{
            "customLocation" = $ikey.path.replace("HKLM:\","")
            "customValueName" = $ikey.name
            "customRegType" = $type
            "customData" = $iKey.value
    
        }
    }
    $newkeysOut += $newKey
}

if ($null -ne $existingkeys) {
    $newkeysOut += $existingkeys
}

# Contiune building the body - putting the structure together
$newvalue.value += $newkeysOut
$newvalue.configFieldID = $response.values.configFieldID
$newvalue.configFieldName = $response.values.configFieldName
$newvalue.sensitive = $response.values.sensitive

$body.name = $policyName
$body.template = @{"id"="5f07273cb544065386e1ce6f"} # hardcoding the universally applicable template ID
$body.values += $newvalue
$body = $body | ConvertTo-Json -Depth 10
$body = $body.Replace("Values","values")

# Making the changes alongside with the existing settings on this policy, capture the response in $change
$change  = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $body
