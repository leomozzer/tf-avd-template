<#
Script to configure the RDInfraAgent and FSLogix registry keys and restart the service RDAgentBootLoader
#>
function CreateHostPool{
    param(

        [Parameter(Mandatory=$true)]
        [string] $poolName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Pooled", "Personal")]
        [string] $hostPoolType,

        [Parameter(Mandatory=$true)]
        [ValidateSet("BreadthFirst", "DepthFirst")]
        [string] $loadBalancerType,

        [Parameter(Mandatory=$true)]
        [ValidateSet("RemoteApp", "Desktop")]
        [string] $preferredAppGroupType,

        [Parameter(Mandatory=$true)]
        [string] $maxSessionLimit,

        [Parameter(Mandatory=$true)]
        [string] $localtion,

        [Parameter(Mandatory=$true)]
        [string] $environment
    )

    $hostPoolName = "vdpool-$poolName-$location-$environment"
    $resourceGroupName = "rg-$hostPoolName"

    $parameters = @{
        Name = "vdpool-$poolName-$environment"
        ResourceGroupName = "rg-vdpool-$poolName-$location-$environment"
        HostPoolType = $hostPoolType
        LoadBalancerType = $loadBalancerType
        PreferredAppGroupType = $preferredAppGroupType
        MaxSessionLimit = $maxSessionLimit
        Location = $localtion
    }

    try {
        New-AzWvdHostPool @parameters
    }
    catch {
        Write-Error "Error creating host pool"
        Write-Error $_
    }
}