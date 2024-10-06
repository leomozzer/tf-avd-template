<#
Script to configure FSLogix registry keys
#>
param(
    [Parameter(Mandatory=$true)]
    [string] $azureStaName,

    [Parameter(Mandatory=$true)]
    [string] $fileShareName,

    [Parameter(Mandatory=$true)]
    [string] $fsLogixDirectoryValue,

    [Parameter(Mandatory=$true)]
    [string] $domainName,

    [Parameter(Mandatory=$true)]
    [string] $localAdminUser
)
$listOfKeys = @()
$Enabled = @{
  "name" = "Enabled"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $Enabled
$DeleteLocalProfileWhenVHDShouldApply = @{
  "name" = "DeleteLocalProfileWhenVHDShouldApply"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $DeleteLocalProfileWhenVHDShouldApply
$FlipFlopProfileDirectoryName = @{
  "name" = "FlipFlopProfileDirectoryName"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $FlipFlopProfileDirectoryName
$IsDynamic = @{
  "name" = "IsDynamic"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $IsDynamic
$LockedRetryCount = @{
  "name" = "LockedRetryCount"
  "value" = 3
  "type" = "DWORD"
}
$listOfKeys += $LockedRetryCount
$PreventLoginWithFailure = @{
  "name" = "PreventLoginWithFailure"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $PreventLoginWithFailure
$PreventLoginWithTempProfile = @{
  "name" = "PreventLoginWithTempProfile"
  "value" = 1
  "type" = "DWORD"
}
$listOfKeys += $PreventLoginWithTempProfile
$ReAttachIntervalSeconds = @{
  "name" = "ReAttachIntervalSeconds"
  "value" = 21
  "type" = "DWORD"
}
$listOfKeys += $ReAttachIntervalSeconds
$RoamSearch = @{
  "name" = "RoamSearch"
  "value" = 0
  "type" = "DWORD"
}
$listOfKeys += $RoamSearch
$VHDLocations = @{
  "name" = "VHDLocations"
  "value" = "\\$azureStaName.file.core.windows.net\$fileShareName\$fsLogixDirectoryValue"
  "type" = "STRING"
}
$listOfKeys += $VHDLocations
$VolumeType = @{
  "name" = "VolumeType"
  "value" = "VHDX"
  "type" = "STRING"
}
$listOfKeys += $VolumeType

if (($azureStaName -eq "") -or ($fileShareName -eq "") -or ($fsLogixDirectoryValue -eq "")) {
    return "Missing required values"
}
$fsLogixProfile = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
try {
    foreach($key in $listOfKeys){
        Write-Host "Checking 'HKLM:\SOFTWARE\FSLogix\Profiles\$($key.name)'"
        $getItemProperty = Get-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name $($key.name) -ErrorAction SilentlyContinue
        If ($getItemProperty) {
            Write-host -f Green "Property HKLM:\SOFTWARE\FSLogix\Profiles\$($key.name)"
        }
        else {
            # Value does not exist
            Write-host -f Yellow "Value $($key.value) doesn't Exists! with $($key.name)"
            New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "$($key.name)" -Value $key.value -PropertyType $key.type
        }
    }
    #Adding the current admin user ad member of the FSLogix ODFC Exclude List 
    Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member "$($env:COMPUTERNAME)\$($localAdminUser)"
    Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member "$($domainName)\AVD_FSLogix_Exclude"

    #Adding the current admin user ad member of the FSLogix Profile Exclude List 
    Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "$($env:COMPUTERNAME)\$($localAdminUser)"
    Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "$($domainName)\AVD_FSLogix_Exclude"

    ## Adding Kerberos REG KEYS for Kerberos
    ##Only use when it's:
    ## - https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-hybrid-identities-enable
    ## - https://learn.microsoft.com/en-us/azure/virtual-desktop/create-profile-container-azure-ad
    #reg add HKLM\Software\Policies\Microsoft\AzureADAccount /v LoadCredKeyFromProfile /t REG_DWORD /d 0
    #reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters /v CloudKerberosTicketRetrievalEnabled /t REG_DWORD /d 1
    #New-ItemProperty -Path "HKLM\Software\Policies\Microsoft\AzureADAccount" -Name "LoadCredKeyFromProfile" -Value 1 -PropertyType "REG_DWORD"

}
catch {
    Write-Error "Error updating registry key: $_"
}