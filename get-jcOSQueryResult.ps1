

$cmdName = "Edge Extensions - JCQSQuery"
#@{'and' = @("name:`$regex:RadiusCert*", "workflowId:`$eq:6406532738e1a32cafa24260")}
$commandsResultBody = @{
    filter = @{
        'and' = @("name:`$eq:$cmdName" )
    }
    fields = 'response.data.exitCode response.data.output system'
}| ConvertTo-Json -Depth 99
$results = Search-JcSdkCommandResult -body $commandsResultBody 

$outPutResults = @()

foreach ($r in $results){
    $edgeExt = $r.DataOutput | ConvertFrom-Json -Depth 99 
    foreach ($e in $edgeExt){
        $tempOutput = "" | select author,browser_type,from_webstore,identifier,install_time,manifest_hash,path,permissions,profile,profile_path,version,systemID
        $tempOutput.author = $e.author
        $tempOutput.browser_type = $e.browser_type
        $tempOutput.from_webstore = $e.from_webstore
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




$outPutResults | Export-Csv edgeExtReport.csv