param(
    [Parameter(Mandatory=$true)]
    [string] $subscriptionID,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $hostPoolName,

    [Parameter(Mandatory=$true)]
    [string] $messageLanguage,

    [Parameter(Mandatory=$true)]
    [int] $minutes
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
Connect-AzAccount -Identity

Import-Module Az.DesktopVirtualization

# set and store context
$AzureContext = Set-AzContext –SubscriptionId $subscriptionID

$messageOptions = @{
    "en" = @{
        "title" = "Session Shutdown"
        "body" = "You will be logged out in $minutes minutes. Remember to save your work."
    }
    "de" = @{
        "title" = "Sitzung beenden"
        "body" = "Sie werden in $minutes Minuten abgemeldet. Denken Sie daran, Ihre Arbeit zu speichern."
    }
}

$msgtitle = $messageOptions[$messageLanguage]["title"]
$msgbody = $messageOptions[$messageLanguage]["body"]

$sessionhost = Get-AzWvdSessionHost -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName
foreach ($server in $sessionhost){
    Write-Output $server
    $serverName = $server.name
    $sessionHostName = $serverName.Split("/")[1]
    $sessions = Get-AzWvdUserSession -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName -SessionHostName $sessionHostName
    foreach($session in $sessions){
        $userPrincipalName = $session.UserPrincipalName
        $sessionState= $session.SessionState
        $sessionName = $session.Name
        $userSessionID = $sessionName.Split("/")[2]
        Send-AzWvdUserSessionMessage -HostPoolName $hostpoolname -ResourceGroupName $resourceGroupName -SessionHostName $sessionHostName  -UserSessionId $userSessionID -MessageTitle $msgtitle -MessageBody $msgbody
    }
}