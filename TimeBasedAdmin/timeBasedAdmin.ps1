# Connect to your JC Tenant - Manager role is good enough!
#Connect-JCOnline -JumpCloudApiKey $env:JCRW #strongly suggest storing the API key in the system env variable,
## i.e. https://medium.com/@sonykey2003/protect-your-secrets-in-environment-variables-a07eff7699f0

# Get JC user   
$username = Read-Host  "What is the user name you want to promot to admin"
[Int32]$time = Read-Host "How long you want to grant the admin privilege, in mins? (input the integer - i.e. 15,20,30)"
$jcuser = Get-JCUser -username $username

# List the assoicated devices
$systems = Get-JCAssociation -Type user -Id $jcuser.id -TargetType system
$outSystems = @()
foreach ($s in $systems){
    $sysinfo = Get-JCSystem -SystemID $s.targetId 
    if ($sysinfo.osFamily -ne 'ios' -and $sysinfo.osFamily -ne 'android'){
        $outSystems += $sysinfo
    }
}

Write-Host "Here is a list of systems $username is binding to:"
foreach ($system in $outSystems){
    if ($system.active) {
        Write-Host "$($system.hostname)  --- is online" -ForegroundColor Green
    }
   else {
    Write-Host "$($system.hostname) --- is offline, changes might not be applied until it connects back online." -ForegroundColor Yellow
   }
     
}

$targetHostname =  Read-Host  "Which system you are prompting the user to admin? Pick a hostname (online) from above"
$targetSystem = $outSystems | where {$_.hostname -eq $targethostname}
Set-JCSystemUser -Username $jcuser.username -SystemID $targetSystem.id  -Administrator $true

# Set trigger name depends on the os type
switch ($targetSystem.osFamily) {
    "windows" {$triggerName = "WinToast"}
    "darwin" {$triggerName = "MacToast"}
}

# Get cmd info
$cmd = Get-JCCommand -name $triggerName

#start a timer 
$startTime = Get-Date
$endTime = $startTime.AddMinutes($time)  # Adjust the time as needed


# create cmd trigger for toast msg on Win
# create cmd trigger for scheduling and pass in the params & JC api key for revoking



# Start a background job to keep track of the time
Write-Output 'Kicking off a background job for $username...Check the status by using "receive-Job -id $job.id -keep" '
$job = Start-Job -Name ($username+'Temp Admin '+$time+' mins') -ScriptBlock {

    param ($env:JCRW,$time,$startTime,$endTime,$jcuser,$targetSystem,$triggerName,$cmd)
    Connect-JCOnline -JumpCloudApiKey $env:JCRW -force
    # Trigger cmd function
    function Trigger-JCCmd {
        param (
            [int]$remainingTime,
            $JCAPIKEY=$env:JCRW,
            $TriggerName
        )
        $baseUrl = 'https://console.jumpcloud.com/api/command/trigger/'
        $headers = @{
            "x-api-key" = $JCAPIKEY
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        $body = @{
            "remainingTime" = $remainingTime
        } | ConvertTo-Json

       $response = Invoke-RestMethod -Uri ($baseUrl+$triggerName) -Method Post -Headers $headers -Body $body 
       return $response
    }

    # Binding the cmd trigger to the designated system
    Set-JcSdkCommandAssociation -CommandId $cmd._id -Op "add" -Type 'system' -Id $targetSystem._id
    

    do {
        # Trigger cmd function
        $currentTime = Get-Date
        [Int32]$remainingTime = [math]::Ceiling(($endTime - $currentTime).TotalMinutes)
        Write-Output "$($jcuser.username)'s admin previllege will be revoked at: $endtime,  time remianing: $remainingTime mins"
        sleep 60
        if ($remainingTime -lt $time * 0.3 ) {
            Write-Output "Triggering $($cmd.name) to $($targetSystem.hostname)..."
            Trigger-JCCmd -TriggerName $triggerName -remainingTime $remainingTime

        }
        else {
            Write-Output "$($time * 0.3)_Nothing to trigger for $($targetSystem.hostname)..."
        }


    } while ($currentTime -lt $endTime)
    

    # Times up, reverting back
    set-JCSystemUser -Username $jcuser.username -SystemID $targetSystem.id  -Administrator $false
    Write-Output "$($jcuser.username)'s admin previllege is revoked at: $currentTime."

    # remove once it done.
    Set-JcSdkCommandAssociation -CommandId $cmd._id -Op "remove" -Type 'system' -Id $targetSystem._id

} -ArgumentList $env:JCRW,$time,$startTime,$endTime,$jcuser,$targetSystem,$triggerName,$cmd

# Wait for the job to finish and get the remaining time
receive-Job -id $job.id -keep


# To clean:
# Clean up the job
#Remove-Job $job

#Write-Host "Remaining minutes: $remainingMinutes"

# setup a cmd trigger for Win/Mac, set timeout according to the ^ timer, send notification within the cmd, 
# and demote the user once timeout. 
## pop a msg in Win 5 mins before the timer runs out
### create a JC cmd and bind to the device ^


# New IDEA - 
## Create a cmd trigger pass in the API key - 
## Run schedule within the cmd and track the output of remaining mins - 
## Send toast msgs to the logged on user - 
## Revoke the permission once time is up - 
## Progress is trackable in cmd results.    


#Invoke-JCCommand -trigger ToastTest -NumberOfVariables 1 -Variable1_name "Testkey" -Variable1_value $env:JC