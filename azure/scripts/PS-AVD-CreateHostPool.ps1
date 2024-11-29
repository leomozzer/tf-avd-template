<#
    Example: 
    CreateHostPool -poolName "desktop" -hostPoolType "Pooled" -loadBalancerType "BreadthFirst" `
        -preferredAppGroupType "RailApplications" -maxSessionLimit 10 -location "eastus" -environment dev
#>
. "PS-General-LocationHandler.ps1"
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
        [ValidateSet("RailApplications", "Desktop")]
        [string] $preferredAppGroupType,

        [Parameter(Mandatory=$true)]
        [string] $maxSessionLimit,

        [Parameter(Mandatory=$true)]
        [string] $location,

        [Parameter(Mandatory=$true)]
        [string] $environment
    )

    $locationPrefix = Get-LocationPrefix -location $location

    $hostPoolName = "vdpool-$poolName-$locationPrefix-$environment"
    $resourceGroupName = "rg-$hostPoolName"

    #Check if resource group exists
    if( -not (Get-AzResourceGroup -Name $resourceGroupName -location $location -ErrorAction SilentlyContinue)){
        Write-Output "Resource group '$resourceGroupName' does not exist in location '$location'."
        Write-Output "Creating resource group '$resourceGroupName'"
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    
    $parameters = @{
        Name = "vdpool-$poolName-$environment"
        ResourceGroupName = $resourceGroupName
        HostPoolType = $hostPoolType
        LoadBalancerType = $loadBalancerType
        PreferredAppGroupType = $preferredAppGroupType
        MaxSessionLimit = $maxSessionLimit
        Location = $location
    }

    try {
        New-AzWvdHostPool @parameters
    }
    catch {
        Write-Error "Error creating host pool"
        Write-Error $_
    }
}