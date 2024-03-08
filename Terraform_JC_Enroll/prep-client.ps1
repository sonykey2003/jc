<script>
   winrm quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
   netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
</script>
<powershell>
    # Set Administrator password
    $admin = [adsi]("WinNT://./administrator, user")
    $admin.psbase.invoke("SetPassword", "${admin_pw}")
    Get-WindowsFeature "Telnet-Client" |Install-WindowsFeature
    Set-ExecutionPolicy RemoteSigned
    cd $env:temp |`
     Invoke-Expression; `
     Invoke-RestMethod -Method Get -URI https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1 -OutFile InstallWindowsAgent.ps1 |`
     Invoke-Expression; ./InstallWindowsAgent.ps1 -JumpCloudConnectKey "${jc-connect-key}"
    sleep 30
    Set-ExecutionPolicy Restricted
</powershell>