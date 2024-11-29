function Get-LocationPrefix {
    param (
        [string]$location
    )

    # Define a hashtable mapping locations to region prefixes
    $regionMap = @{
        "eastus"             = "eus"
        "east us"            = "eus"
        "West US"            = "wus"
        "North Central US"   = "ncus"
        "South Central US"   = "scus"
        "East US 2"          = "eus2"
        "West US 2"          = "wus2"
        "Central US"         = "cus"
        "West Central US"    = "wcus"
        "Canada East"        = "canadaeast"
        "Canada Central"     = "canadacentral"
        "westeurope"         = "weu"
        "west europe"        = "weu"
        "North Europe"       = "neu"
        "northeurope"        = "neu"
        "UK South"           = "uks"
        "UK West"            = "ukw"
        "France Central"     = "francecentral"
        "France South"       = "francesouth"
        "Germany North"      = "germanynorth"
        "Germany West"       = "germanywest"
        "Switzerland North"  = "swnorth"
        "Switzerland West"   = "swwest"
        "Norway East"        = "noeast"
        "Norway West"        = "nowest"
    }

    # Normalize the input to ensure case-insensitivity
    $location = $location.Trim().ToLower()

    # Check if the location exists in the map and return the prefix
    if ($regionMap.ContainsKey($location)) {
        return $regionMap[$location]
    } else {
        Write-Output "Region prefix not found for location: $location"
        return $null
    }
}