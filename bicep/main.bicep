targetScope = 'subscription'

@description('Timestamp used to uniquely name deployed modules to retain all deployment history')
param deploymentTimestamp string = utcNow()

@description('The ID of the user who should be allowed to manage Terraform state')
param userId string

@description('Storage redundancy (recommended to use at least ZRS)')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
])
param skuName string = 'Standard_ZRS'

@description('Resource group for Terraform state resources')
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-terraform-backend'
  location: deployment().location
  tags: {
    'owner': 'terraform'
  }
}

module storage 'modules/storage.bicep' = {
  scope: rg
  name: '${deploymentTimestamp}-storage-module'
  params: {
    skuName: skuName
    userId: userId
  }
}

var template = '''
terraform {{
  backend "azurerm" {{
    resource_group_name  = "{0}"
    storage_account_name = "{1}"
    container_name       = "{2}"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
    subscription_id      = "{3}"
    tenant_id            = "{4}"
  }}
}}
'''

var aad = tenant().tenantId
var sub = subscription().subscriptionId
var acc = storage.outputs.account
var con = storage.outputs.container

output backendBlock string = format(template, rg.name, acc, con, sub, aad)
