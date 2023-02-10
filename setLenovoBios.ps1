 # Pick a setting to set
 $settingName = "WakeOnLANDock"

 # Getting the current setting
 $currentSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosSetting | Select-Object CurrentSetting
 $currentValue = ($currentSettings | Where-Object {$_.CurrentSetting -Like "*$settingName*"}).CurrentSetting.replace(',','=')
 $settingValues = (gwmi –class Lenovo_GetBiosSelections –namespace root\wmi).GetBiosSelections($settingname).selections
 Write-Host "Settings available for $settingname : $settingvalues"
 Write-Host "The current setting is $currentValue"
 
 # Setting the new value
 $newValue =  $settingvalues.Split(',')[1] # Pick and choose a value, in this case is "disable"
 Write-Host "$settingname is going to be set as $newvalue.."
 
 $setSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_SetBiosSetting
 $setSettings.SetBiosSetting("$settingName,$newValue")
 
# Connect to the Lenovo_SetBiosSetting WMI class
 Write-Host "Saving the bios setting..."
 $SaveSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_SaveBiosSettings
 $SaveSettings.SaveBiosSettings()
  
   
 