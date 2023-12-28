# Connect to your JC Tenant - Manager role is good enough!
Connect-JCOnline "your-Manager-admin-api-key"


# Create the toast msg cmd trigger for Windows
$winTriggerName = "WinToast"
$winCmd = @'

# Writting the env var to a file for the user session to access
$env:remainingTime | Out-File  $env:public\rt.txt -Force

# Make sure the required modules are installed
$modules = get-module -ListAvailable burnttoast,runasuser
 if ($modules.count -ne 2){
    Install-Module BurntToast,RunAsUser -force

 }

# Popping the msg
$scriptBlock = {
  $remainingTime = get-content  C:\Users\Public\rt.txt; New-BurntToastNotification -Text "Your admin privilege has been granted, it will be revoked in $remainingTime mins"
}
invoke-ascurrentuser -scriptblock $scriptBlock

# Cleaning up
remove-item $env:public\rt.txt -force

'@

New-JCCommand -commandType windows -launchType trigger -name $winTriggerName -trigger $winTriggerName -command $winCmd 

# Create the toast msg cmd trigger for MacOS
$MacTriggerName = "MacToast"
$MacCmd = @'

# get the current user's UID
uid=$(id -u "$currentUser")
# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    #launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    launchctl asuser "$uid" sudo -u "$currentUser" "$@" -c "echo $remainingTime"
 
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    # exit 1
  fi
}

osascript -e "display dialog \"Your admin privilege has been granted, it will be revoked in $remainingTime mins\" buttons {\"OK\"}"


'@

New-JCCommand -commandType mac -launchType trigger -name $MacTriggerName -trigger $MacTriggerName -command $MacCmd 