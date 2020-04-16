#!/bin/sh

# Sets up requirements before running TF.

SUBSCRIPTION_ID=$1

SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
az group create --name rg-covidsubs-terraform --location westeurope
az storage account create --name stordeployment --resource-group rg-covidsubs-terraform --sku Standard_LRS --kind StorageV2 --encryption-services blob --access-tier hot
az storage container create --auth-mode login --name tfstate --account-name stordeploy
