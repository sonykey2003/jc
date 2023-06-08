# Use your JC api key to connect-jconline

# The cmdrunner you wanted to pinpoint and remove from the cmd
$cmdrunnerID = '64815632b3315f242f315e86' #get this on admin console UI only - i.e. :
#click the cmd runner admin at adminstrator page https://console.jumpcloud.com/#/settings/administrators/details/<admin_id>
$replacedCmdRunnerID = "6306e843c1473ed4ae36de61" #replace by another cmdrunner admin's id if required, by default will remove ALL cmdrunners for the cmd

$cmds = Get-JCCommand 
foreach($c in $cmds){
    $cmdrunners = (Get-JCCommand -ByID $c._id| select commandrunners).commandrunners
    if ("" -ne $cmdrunners){
        foreach ($cr in $cmdrunners) {
            if ($cr -eq $cmdrunnerID){
                Write-Host "found $cmdrunnerID bind on cmd name: $($c.name)...removing" -ForegroundColor Red
                Set-JcSdkCommand -CommandRunners $replacedCmdRunnerID  -CommandType $c.commandType -Command $c.command -Name $c.name -Id $c._id
            }
        }
   
    }
    else{
        Write-Host "$cmdrunnerID NOT bind on cmd name: $($c.name)...All good!" -ForegroundColor Green
    }
}

