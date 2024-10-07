# Terraform AVD Template
This repository has the objective as a cake recipe when deploying new AVD environments
## Hybrid Configuration
- Deploys the AVD environmet in hybrid environment
- Create Host Pool
- Create Workspace
- Create Application group (when is Desktop app). Remote App instill not ready
- Create VM and vm resources like OS disk and NIC
- Perform Domain Join
- Add VM into host pool

## Configuration
It's important to have the following resources already created and the configurations mentioned already made
- Available Active Directory
   - It was used the Azure Template to deploy a new Win Server to be our Domain Controler
- Azure Tenant
- Virtual Network
- Key Vault
- User with permission of:
  - Contributor at Subscription level
## Repo Folder Structure

```bash
📂.github
  └──📂actions
      └──📂azure-backend
          └──📜action.yaml
      └──📂terraform-apply
          └──📜action.yaml
      └──📂terraform-plan
          └──📜action.yaml
  └──📂workflows
      ├──📜audit.yml
      ├──📜terraform-apply.yml
      ├──📜terraform-deploy.yml
      ├──📜terraform-deply-bash.yml
      └──📜terraform-plan.yml
📂scripts
  ├──📜terraform-apply.tf
  ├──📜terraform-backend-local.tf
  ├──📜terraform-backend.tf
  ├──📜terraform-destoy.tf
  └──📜terraform-plan.tf
📂terraform-main
  ├──📜main.tf
  ├──📜outputs.tf
  └──📜variables.tf
📂terraform-modules
  └──📂module1
      ├──📜main.tf
      ├──📜outputs.tf
      └──📜variables.tf
```

## Terraform Modules
### AVD
Module that deploys and Azure Virtual Desktop environment
Provide the following information into the `<environment>.tfvars` like `prod.tfvars`
```terraform
customershort_name  = "<customershortname>"
environment         = "prod"
avd_subscription_id = ""

avd_definition = [
  {
    subscription_id = ""
    location        = "eastus"
    identifier = [{
      name                     = "desktop"
      app_group_type           = "Desktop"
      hostpool_type            = "Pooled"
      load_balancer_type       = "BreadthFirst"
      number_vms               = 1
      maximum_sessions_allowed = 5
      ou_path                  = "<OUPath>"
    }]
  }
]

custom_rdp_properties = "drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:0;use multimon:i:1;enablerdsaadauth:i:1;autoreconnection enabled:i:1"

domain_type              = "AD"
domain_name              = "<domain controller name>"

rg_vnet_name             = ""
vnet_name                = ""
snet_name                = ""


### Optional parameters
key_vm_credentials_name                = ""
key_vm_credentials_resource_group_name = ""
vm_source_image_id                     = "<Gallery image id>" 

key_vault_resource_group = ""
key_vault_name           = ""
vm_admin_username        = ""
vm_admin_password        = ""

```

## [Workflows](workflows)
### [terraform-deply-bash](.github/workflows/terraform-deply-bash.yml)
- When using this script to run the terraform, first replace the values of the following variables in the files:
  - [terraform-backend.sh](./scripts/terraform-backend.sh)
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod

  # Set the desired values for the backend configuration
  LOCATION=eastus
  RESOURCE_GROUP_NAME="rg" #name of the resource group where the storage account with the state files will be saved
  STORAGE_ACCOUNT_NAME="stac" #storage account where the state files will be saved
  CONTAINER_NAME="states" #location optional
  KEY="$ENVIRONMENT.tfstate"
  ```

  - [terraform-plan.sh](./scripts/terraform-plan.sh)
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved

  VAR_FILE=$ENVIRONMENT.tfvars
  PLAN_FILE=$ENVIRONMENT.plan
  ```

  - [terraform-apply.sh](./scripts/terraform-apply.sh)
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  PLAN_FILE=$ENVIRONMENT.plan
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved
  ```
- Make sure that the secrets below are configured and available:
   - AZURE_SP
   - ARM_CLIENT_ID
   - ARM_CLIENT_SECRET
   - ARM_SUBSCRIPTION_ID
   - ARM_TENANT_ID
