# Azure backend for Terraform state

Use Azure Bicep to set up a Terraform backend in Azure to store your state files.

## Prerequisites

To follow along the instructions in this document you will need to install the following requirements.

- Azure CLI
  - Install using the instructions for your OS [here](https://docs.microsoft.com/cli/azure/install-azure-cli)
- Azure Bicep CLI (version 4.1008 or later)
  - Install using the Azure CLI `az bicep install` or upgrade to the latest version with `az bicep upgrade`
- Terraform
  - Install using the instructions for your OS [here](https://learn.hashicorp.com/tutorials/terraform/install-cli)

Before you proceed, set the default Azure subscription in your terminal.

```
az account set --subscription <subsctription name or ID>
```

For the following guide it is assumed that you are the owner of the subscription.

## Deploy the Azure Terraform backend

You can inspect [main.bicep](./bicep/main.bicep) and [storage.bicep](./bicep/modules/storage.bicep) to see what resources will be created. The `main.bicep` file takes one mandatory parameter: `userId`. In the example below this parameter will be set to the user ID of the one who issues the command. The provided user will be added as a blob data contributor on the storage account where the state files are stored. This allows us to use Azure AD as the authentication mechanism instead of a storage account access key. Note that if several users should be able to use the Azure backend they will also need to be given this role assignment.

In the root of this repository, run the following Azure CLI command.

```bash
$ az deployment sub create \
    --name terraform-backend \
    --template-file bicep/main.bicep \
    --location northeurope \
    --query properties.outputs.backendBlock.value \
    --parameters userId=$(az ad signed-in-user show --query objectId --output tsv) \
    --output tsv
```

When the deployment is complete you will end up with output similar to the following.

```
terraform {
  backend "azurerm" {
    resource_group_name  = "<resource group name>"
    storage_account_name = "<storage account name>"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
    subscription_id      = "<subscription id>"
    tenant_id            = "<tenant id>"
  }
}
```

You will use this block in your Terraform configuration to tell Terraform to store the state file in Azure. The only value in the configuration that you can change out-of-the-box is `key`. The value provided to this attribute determines the name of the state file. This value should be unique for each distinct Terraform configuration you deploy using this backend.

## Use the Azure Terraform backend

Open [main.tf](./terraform/main.tf) and add the `terraform` block to the configuration. The file should look similar to the following.

```
terraform {
  backend "azurerm" {
    resource_group_name  = "<resource group name>"
    storage_account_name = "<storage account name>"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
    subscription_id      = "<subscription id>"
    tenant_id            = "<tenant id>"
  }
}

provider "random" {}

resource "random_integer" "number" {
  min = 0
  max = 10000
}

output "number" {
  value = random_integer.number.result
}
```

Deploy the Terraform configuration to verify that the remote backend works.

```bash
$ cd terraform
$ terraform init
$ terraform apply -auto-approve
```

You should se an output similar to the following.

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # random_integer.number will be created
  + resource "random_integer" "number" {
      + id     = (known after apply)
      + max    = 10000
      + min    = 0
      + result = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + number = (known after apply)
random_integer.number: Creating...
random_integer.number: Creation complete after 0s [id=5694]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

number = 5694
```
