# Reading the CSV for HR data#
################################################################################

$csv = "/your/path/to/OnboardingCSVSample.csv" 
$companyDomain = "yourcompany.com" # use your corp email domain here

################################################################################
# Do not edit below
################################################################################

# getting the data from via api
$data = Import-Csv $csv

# creating the new users
foreach ($e in $data){

    # generating the user name by convention: firstname.lastname
    $username = $e."First Name".trim().tolower() + '.' + $e."Last Name".trim().tolower()
    $email = $username + "@"+ $companyDomain
    $displayname = $e."First Name" + ' ' + $e."Last Name"

    # coverting the start date to datetime structure
    $formatString = "yyyy-MM-ddTHH:mm:ss.fffZ"
    $onboardingdate = get-date $e."start date" -Format $formatString  
    
    try {
    $newuser =  New-JCUser -firstname $e."First Name"`
        -lastname $e."Last Name" -email $email`
        -location $e.location -employeeIdentifier $e."Employee Id"`
        -displayname $displayname -jobTitle $e."Job Title"`
        -department $e.Department -username $username

    New-JcSdkBulkUserState -StartDate $onboardingdate -State ACTIVATED -UserIds $newuser._id
    }
    catch {
        Write-Error $_.Exception.Message # Will display an error if the user by any chance already been created
    }
     
}