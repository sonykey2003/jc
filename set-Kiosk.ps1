
# -----------------------------------------------------------------------------
# Script: DOConfig.ps1
# Version: 1.0.1
# Author: Shawn Song
# Reference: https://learn.microsoft.com/en-us/windows/win32/dmwmibridgeprov/mdm-bridge-wmi-provider-portal
# Notes: this script only works under localsystem account, suggested to run in JumpCloud's cmd or using psexec.
# -----------------------------------------------------------------------------

# Defining the classname
# https://learn.microsoft.com/en-us/windows/configuration/kiosk-mdm-bridge
# https://learn.microsoft.com/en-us/windows/configuration/kiosk-methods
# This is for multi-app kiosk mode
$classname = "MDM_AssignedAccess"
$namespace = "root\cimv2\mdm\dmmap" 
$profileGuid = [guid]::NewGuid()
$kioskAccount = "chris.lam"

# Hardcoding the InstanceID & ParentID for the new CIM instance
$obj = @{
    instanceID="AssignedAccess"
    ParentID="./Vendor/MSFT/"

}

$session = Get-CimInstance -namespace $namespace -ClassName $classname

if ($null -eq $session){
    #creating cim instance if it's not there
    $session = New-CimInstance -Namespace $namespace -ClassName $classname -Property $obj
}

# Injecting the app config as XML
Add-Type -AssemblyName System.Web
$session.Configuration = [System.Web.HttpUtility]::HtmlEncode(@"
<?xml version="1.0" encoding="utf-8" ?>
<AssignedAccessConfiguration xmlns="http://schemas.microsoft.com/AssignedAccess/2017/config">
  <Profiles>
    <Profile Id="{9A2A490F-10F6-4764-974A-43B19E722C23}">
      <AllAppsList>
        <AllowedApps>
          <App AppUserModelId="Microsoft.ZuneMusic_8wekyb3d8bbwe!Microsoft.ZuneMusic" />
          <App AppUserModelId="Microsoft.ZuneVideo_8wekyb3d8bbwe!Microsoft.ZuneVideo" />
          <App AppUserModelId="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
          <App AppUserModelId="Microsoft.BingWeather_8wekyb3d8bbwe!App" />
          <App AppUserModelId="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
          <App DesktopAppPath="%windir%\system32\mspaint.exe" />
          <App DesktopAppPath="C:\Windows\System32\notepad.exe" />
        </AllowedApps>
      </AllAppsList>
      <StartLayout>
        <![CDATA[<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
                      <LayoutOptions StartTileGroupCellWidth="6" />
                      <DefaultLayoutOverride>
                        <StartLayoutCollection>
                          <defaultlayout:StartLayout GroupCellWidth="6">
                            <start:Group Name="Group1">
                              <start:Tile Size="4x4" Column="0" Row="0" AppUserModelID="Microsoft.ZuneMusic_8wekyb3d8bbwe!Microsoft.ZuneMusic" />
                              <start:Tile Size="2x2" Column="4" Row="2" AppUserModelID="Microsoft.ZuneVideo_8wekyb3d8bbwe!Microsoft.ZuneVideo" />
                              <start:Tile Size="2x2" Column="4" Row="0" AppUserModelID="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
                              <start:Tile Size="2x2" Column="4" Row="4" AppUserModelID="Microsoft.BingWeather_8wekyb3d8bbwe!App" />
                              <start:Tile Size="4x2" Column="0" Row="4" AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
                            </start:Group>
                            <start:Group Name="Group2">
                              <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Paint.lnk" />
                              <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk" />
                            </start:Group>
                          </defaultlayout:StartLayout>
                        </StartLayoutCollection>
                      </DefaultLayoutOverride>
                    </LayoutModificationTemplate>
                ]]>
      </StartLayout>
      <Taskbar ShowTaskbar="true"/>
    </Profile>
  </Profiles>
  <Configs>
    <Config>
      <Account>$kioskAccount/Account>
      <DefaultProfile Id="{$($profileGuid.Guid)}"/>
    </Config>
  </Configs>
</AssignedAccessConfiguration>
"@)

Set-CimInstance -CimInstance $session