

$cmdName = "JCQSQuery"
#@{'and' = @("name:`$regex:RadiusCert*", "workflowId:`$eq:6406532738e1a32cafa24260")}
$commandsResultBody = @{
    filter = @{
        'and' = @("name:`$eq:$cmdName" )
    }
    fields = 'response.data.exitCode response.data.output system'
}| ConvertTo-Json -Depth 99
$results = Search-JcSdkCommandResult -body $commandsResultBody 

foreach ($r in $results){

}

