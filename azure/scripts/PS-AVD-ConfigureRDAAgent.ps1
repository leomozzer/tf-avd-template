<#
Script to configure the RDInfraAgent and FSLogix registry keys and restart the service RDAgentBootLoader
#>
param(
    [Parameter(Mandatory=$true)]
    [string] $registrationTokenValue
)

if ($registrationTokenValue -eq "") {
    return "Missing required values"
}
$RDInfraAgentPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
$IsRegisteredValue = "0" #By default this value will be 1 (enabled)
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
}
catch {
    Write-Error "Error updating registry key: $_"
}