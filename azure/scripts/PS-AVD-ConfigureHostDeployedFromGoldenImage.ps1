<#
Script to configure the RDInfraAgent and FSLogix registry keys and restart the service RDAgentBootLoader
#>
#Uncomment the desired environment
#$fsLogixDirectoryValue = "\\sgavdprofiles01.file.core.windows.net\avdprofiles\vdpool-avd-dev"
#$fsLogixDirectoryValue = "\\sgavdprofiles01.file.core.windows.net\avdprofiles\vdpool-avd-stag"
#$fsLogixDirectoryValue = "\\sgavdprofiles01.file.core.windows.net\avdprofiles\vdpool-avd-prod"
#$fsLogixDirectoryValue = "\\sgavdprofiles01.file.core.windows.net\avdprofiles\vdpool-avddesktop-prod"
#Need to get from the "Registration Key" in the host pool on Azure Portal
#$registrationTokenValue = ""
param(
    [Parameter(Mandatory=$true)]
    [string] $azureStaName,

    [Parameter(Mandatory=$true)]
    [string] $fileShareName,

    [Parameter(Mandatory=$true)]
    [string] $fsLogixDirectoryValue,

    [Parameter(Mandatory=$true)]
    [string] $registrationTokenValue
)

#Standard SKU
#$fsLogixDirectoryValue = "\\sgavdprofiles01.file.core.windows.net\avdprofiles\$fsLogixDirectoryValue"
#PRemium SKU
$fsLogixDirectoryValue = "\\$azureStaName.file.core.windows.net\$fileShareName\$fsLogixDirectoryValue"

Write-Output "Setting timezone to W. Europe Standard Time"
Set-Timezone  -Id "W. Europe Standard Time"
if (($registrationTokenValue -eq "") -or ($fsLogixDirectoryValue -eq "")) {
    return "Missing required values"
}
$RDInfraAgentPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
$IsRegisteredValue = "0" #By default this value will be 1 (enabled)
$fsLogixProfile = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
try {
    #Configure the Host Pool settings
    #Set the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent\IsRegistered to 0
    Write-Output "Changing $($RDInfraAgentPath)\IsRegistered to $IsRegisteredValue"
    Set-ItemProperty -Path $RDInfraAgentPath -Name "IsRegistered" -Value $IsRegisteredValue
    Start-Sleep 10
    #Set the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgen\RegistrationToken to the $registrationTokenValue
    Write-Output "Changing $($RDInfraAgentPath)\RegistrationToken to $registrationTokenValue"
    Set-ItemProperty -Path $RDInfraAgentPath -Name "RegistrationToken" -Value $registrationTokenValue
    Start-Sleep 10
    # Restart RDAgentBootLoader service
    Write-Output "Running the command 'Restart-Service RDAgentBootLoader'"
    Restart-Service RDAgentBootLoader
    Start-Sleep 10
    #Configure the FSLogix settings
    Write-Output "Changing $($fsLogixProfile)\VHDLocations to $fsLogixDirectoryValue"
    Set-ItemProperty -Path $fsLogixProfile -Name "VHDLocations" -Value $fsLogixDirectoryValue
    Start-Sleep 10
}
catch {
    Write-Error "Error updating registry key: $_"
}