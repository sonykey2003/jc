# Set the days
$days = 1 # can be 2 days or more 
$backtrackDays = (get-date).adddays(-$days)

# Gathering the cmd results for purging
$rawResults = Get-JCCommandResult 
# Pagniated approach - optional for orgs have large amount of results
# $rawResults = Get-JcSdkCommandResult -paginate:$false 

$results = $rawResults | where {($_.exitcode -eq 0) -and ($_.responseTime -lt $backtrackDays)} | select _id,responsetime

# Removing
foreach ($r in $results){
    $count += 1 
    write-host "removing $($r._id), $count out of $($results.Count) "
    Remove-JCCommandResult -CommandResultID $r._id -force -Verbose
    
}