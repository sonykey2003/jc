
# Building the Report Object Container
$outputReport = @()

# Set the number of days you wanted to back track
$tracebackDays = 30

# Get all users with usernames only
$usernames = Get-JCUser
foreach ($u in $usernames){ 
    $report = "" | select username,geoip,service,success,client_ip,timestamp,details,event_type,useragent,localUserName
    
    $reportUser = $u.username
    if ("" -ne $u.systemUsername){
      $reportUser = ($u.systemUsername).ToLower()

    }
    # Callin JC DI and back tracking the days defined above
    $loginEvent = Get-JCEvent -Service:('all') -StartTime:((Get-date).AddDays(-$tracebackDays))`
      -SearchTermAnd @{"initiated_by.username" = $reportUser} -ErrorAction SilentlyContinue |`
      sort-object -Descending $_.timestamp -Bottom 1

    $report.username = $u.username
    $report.timestamp = "n.a."
    $report.details = "user has no activity for the past $tracebackDays days "
    $report.localUserName = $u.systemUsername

    
    if ($null -ne $loginEvent){
        $report.geoip = $loginEvent.geoip
        $report.service = $loginEvent.service
        $report.success = $loginEvent.success
        $report.client_ip = $loginEvent.client_ip
        $report.timestamp = $loginEvent.timestamp
        $report.details = $loginEvent.message
        $report.event_type = $loginEvent.event_type
        $report.useragent = $loginEvent.useragent
    }
    $outputReport += $report
}
$outputReport | export-csv lastUserActReport.csv