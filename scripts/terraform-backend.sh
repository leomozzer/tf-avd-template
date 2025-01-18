#!/bin/bash

WORKING_DIR=./terraform-live
ENVIRONMENT=blue

# Set the desired values for the backend configuration
LOCATION=eastus
RESOURCE_GROUP_NAME="rg-lsoavdstac"
STORAGE_ACCOUNT_NAME="lsoavdstac"
CONTAINER_NAME="states"
KEY="$ENVIRONMENT.tfstate"

cd $WORKING_DIR

az group create --location $LOCATION --resource-group $RESOURCE_GROUP_NAME
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --kind StorageV2 --encryption-services blob --access-tier Cool --allow-blob-public-access false
az storage container create --name states --account-name $STORAGE_ACCOUNT_NAME
az storage container create --name plans --account-name $STORAGE_ACCOUNT_NAME
# 
az storage container create --name $ENVIRONMENT-tf-files --account-name $STORAGE_ACCOUNT_NAME

# Create the backend.tf file
cat <<EOL > backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$KEY"
  }
}
EOL

echo "backend.tf file has been created with the specified configuration."

cat <<EOL > provider.tf
provider "azurerm" {
  skip_provider_registration = true
  subscription_id            = var.avd_subscription_id
  features {

  }
}


EOL

#Copy provider and backend file create locally to tffiles container
az storage blob upload \
    --container-name $ENVIRONMENT-tf-files \
    --file provider.tf \
    --name provider.tf \
    --account-name $STORAGE_ACCOUNT_NAME \
    --overwrite

az storage blob upload \
    --container-name $ENVIRONMENT-tf-files \
    --file backend.tf \
    --name backend.tf \
    --account-name $STORAGE_ACCOUNT_NAME \
    --overwrite

az storage blob upload \
    --container-name $ENVIRONMENT-tf-files \
    --file $ENVIRONMENT.tfvars \
    --name $ENVIRONMENT.tfvars \
    --account-name $STORAGE_ACCOUNT_NAME \
    --overwrite