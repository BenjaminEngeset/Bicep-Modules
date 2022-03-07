/*
SUMMARY: Module to deploy an Azure Container Registry with archiving diagnostics logs to a storage account, sending them to a Log Analytics workspace and with policies 
DESCRIPTION: The following components will be options in this deployment
              Diagnostics
              Resource Lock
AUTHOR/S: bengeset96
VERSION: 1.1.0
*/

@minLength(5)
@maxLength(50)
@description('Globally unique name for Azure Container Registry')
param parAcrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Specifies the Azure location where the Azure Container Registry should be created. Default: Returns the resource group location')
param parLocation string = resourceGroup().location

@description('Tag to be applied to resource when deployed. Default: Returns the current (UTC) datetime value in the specified format')
param parDateModified string = utcNow('d')

@description('Tags to be applied to resource when deployed. Default: Empty Object')
param parResourceTags object = {}

var varDefaultResourceTags = {
  ModifiedDate: parDateModified
}

@description('Inherit tags from resource group when deployed. Default: Returns the resource group tags')
var varResourceGroupTags = resourceGroup().tags

@description('Tags to be applied to resource when deployed. Default: parResourceTags, varResourceGroupTags, varDefaultResourceTags')
var varTags = union(parResourceTags, varResourceGroupTags, varDefaultResourceTags)

@description('Azure Container Registry service tier. Default: Premium')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param parAcrSku string = 'Premium'

@description('Enable system-assigned managed identity. Default: true')
param parEnableSystemIdentity bool = true

@description('The list of user-assigned managed identity resource ids to associate with the Azure Container Registry. Default: Empty Object')
@metadata({
  userAssignedIdentityResourceId: {}
})
param parUserAssignedIdentities object = {}

@description('Enable admin user on Azure Container Registry. Default: false')
param parEnableAdminUser bool = false

@description('Enable public network access. Default: Enabled')
@allowed([
  'Disabled'
  'Enabled'
])
param parPublicNetworkAccess string = 'Enabled'

@description('Zone redundancy, Azure Container Registry is minimum replicated across three seperate zones. Default: Disabled')
@allowed([
  'Disabled'
  'Enabled'
])
param parZoneRedundancy string = 'Disabled'

@description('The network rule set for a container registry. Default: Empty Object')
@metadata({
  defaultAction: 'The default action of allow or deny when no other rules match. Valid values are Allow/Deny'
  ipRules: [
    {
      action: 'Allow'
      value: ''
    }
  ]
  virtualNetworkRules: [
    {
      action: 'Allow'
      id: 'Resource ID of a subnet, valid values are subscriptionId, resourceGroupName, providers/Microsoft.Network/virtualNetworks/subnets, vnetName, subnetName'
    }
  ]
})
param parNetworkRuleSet object = {}

@description('Allow trusted Azure services to access restricted registry. Default: None')
@allowed([
  'AzureServices'
  'None'
])
param parNetworkRuleBypassOptions string = 'None'

@description('Azure Container Registry policies. Default: Empty Object')
@metadata({
  exportPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are enabled/disabled'
  }
  quarantinePolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are enabled/disabled'
  }
  retentionPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are enabled/disabled'
    days: 'The number of days to retain an untagged manifest after which it gets purged'
  }
  trustPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are enabled/disabled'
  }
})
param parPolicies object = {}

@description('Diagnostic logs. Default: true')
param parEnableDiagnostics bool = true

@description('Log analytics workspace resource id. Only required if parEnableDiagnostics is set to true. Default: Empty String')
param parLogAnalyticsWorkspaceId string = ''

@description('Storage account resource id. Only required if parEnableDiagnostics is set to true. Default: Empty String')
param parDiagnosticStorageAccountId string = ''

@description('Delete lock. Default: true')
param parEnableDeleteLock bool = true

var varDiagnosticsName = '${resAzureContainerRegistry.name}-dgs'
var varLockName = '${resAzureContainerRegistry.name}-lck'

resource resAzureContainerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: parAcrName
  tags: varTags
  location: parLocation
  sku: {
    name: parAcrSku
  }
  identity: parEnableSystemIdentity ? {
    type: 'SystemAssigned'
  } : !empty(parUserAssignedIdentities) ? {
    type: 'UserAssigned'
    userAssignedIdentities: parUserAssignedIdentities
  } : null
  properties: {
    adminUserEnabled: parEnableAdminUser
    publicNetworkAccess: parPublicNetworkAccess
    zoneRedundancy: parZoneRedundancy
    networkRuleBypassOptions: parNetworkRuleBypassOptions
    networkRuleSet: !empty(parNetworkRuleSet) ? {
      defaultAction: parNetworkRuleSet.defaultAction
      ipRules: parNetworkRuleSet.ipRules
      virtualNetworkRules: parNetworkRuleSet.virtualNetworkRules
    } : {}
    policies: parPolicies
  }
}

resource resDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = if (parEnableDiagnostics) {
  scope: resAzureContainerRegistry
  name: varDiagnosticsName
  properties: {
    workspaceId: empty(parLogAnalyticsWorkspaceId) ? null : parLogAnalyticsWorkspaceId
    storageAccountId: empty(parDiagnosticStorageAccountId) ? null : parDiagnosticStorageAccountId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource resLock 'Microsoft.Authorization/locks@2017-04-01' = if (parEnableDeleteLock) {
  scope: resAzureContainerRegistry
  name: varLockName
  properties: {
    level: 'CanNotDelete'
  }
}

// There is no Microsoft Defender for Containers resource declaration, this is because it should automatically be deployed by Microsoft Defender for Cloud
// It will do auto-provision of the required components

@description('Outputs from the module deployment')
output outAzureContainerRegistryName string = resAzureContainerRegistry.name
output outAzureContainerRegistryId string = resAzureContainerRegistry.id
output outAzureContainerRegistryLoginServer string = resAzureContainerRegistry.properties.loginServer
