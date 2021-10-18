@description('Storage redundancy (recommended to use at least ZRS)')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
])
param skuName string = 'Standard_ZRS'

@description('The ID of the user who should be allowed to manage Terraform state')
param userId string

resource account 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: take('stterraformstate${uniqueString(resourceGroup().id)}', 24)
  location: resourceGroup().location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
  }

  resource bs 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: 'tfstate'
    }
  }
}

var blobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, blobDataContributor)
  scope: account
  properties: {
    principalType: 'User'
    principalId: userId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDataContributor)
  }
}

output account string = account.name
output container string = account::bs::container.name
