param(
    [Parameter(Mandatory=$true)]
    [string] $subscriptionID,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $hostPoolName
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
Connect-AzAccount -Identity

Import-Module Az.DesktopVirtualization

# set and store context
$AzureContext = Set-AzContext –SubscriptionId $subscriptionID

$sessionhost = Get-AzWvdSessionHost -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName
foreach ($server in $sessionhost){
    $serverName = $server.name
    $sessionHostName = $serverName.Split("/")[1]
    $sessions = Get-AzWvdUserSession -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName -SessionHostName $sessionHostName
    foreach($session in $sessions){
        $userPrincipalName = $session.UserPrincipalName
        $sessionState= $session.SessionState
        $sessionName = $session.Name
        $userSessionID = $sessionName.Split("/")[2]
        Write-Output "Logoff user $userPrincipalName from session host $sessionHostName. Session state: $sessionState. Session ID: $userSessionID"
        Remove-AzWvdUserSession -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName -SessionHostName $sessionHostName -Id $userSessionID -Force
    }
}