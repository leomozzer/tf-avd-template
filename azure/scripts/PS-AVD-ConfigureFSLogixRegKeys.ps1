$fslogixContainerPath = "\\staname.file.core.windows.net\containerA\directoryA"

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
  "value" = $fslogixContainerPath
  "type" = "STRING"
}
$listOfKeys += $VHDLocations
$VolumeType = @{
  "name" = "VolumeType"
  "value" = "VHDX"
  "type" = "STRING"
}
$listOfKeys += $VolumeType
foreach($key in $listOfKeys){
    Write-Host "Checking 'HKLM:\SOFTWARE\FSLogix\Profiles\$($key.name)'"
    $getItemProperty = Get-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name $($key.name) -ErrorAction SilentlyContinue
    If ($getItemProperty) {
        Write-host -f Green "Property HKLM:\SOFTWARE\FSLogix\Profiles\$($key.name)"
    }
    else {
        # Value does not exist
        Write-host -f Yellow "Value doesn't Exists!"
        New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "$($key.name)" -Value $key.value -PropertyType $key.type
    }
}


