param(
    [Parameter(Mandatory=$true)]
    [string] $timeZoneName
)


if ($timeZoneName -eq "") {
    return "Missing required values"
}
try {
    Write-Output "Setting timezone to $timeZoneName"
    Set-Timezone  -Id $timeZoneName
    Start-Sleep 10
}
catch {
    Write-Error "Error updating Time Zone: $_"
}