# Calling the API to get the data
# Using an example here where assuming the API is service agnostic
#
################################################################################
$url = 'http://your.hris.com'
$apiKey = "your-api-key"
$headers = @{
    'Content-Type' = 'application/json'
    'x-api-key' = $apiKey
}
################################################################################
# Do not edit below
################################################################################

# getting the data from via api
$data = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

# creating the new users
foreach ($e in $data.employees){

  try {
    $newuser =  New-JCUser -firstname $e.firstName`
     -lastname $e.lastname -email $e.workEmail`
     -location $e.location -employeeIdentifier $e.id`
     -displayname $e.displayname -jobTitle $e.jobTitle`
     -department $e.department -username $e.username

    New-JcSdkBulkUserState -StartDate $e.onboardingDate -State ACTIVATED -UserIds $newuser._id
  }
  catch {
    Write-Error $_.Exception.Message # Will display an error if the user by any chance already been created
  }
     
}