/*
SUMMARY: Module to deploy an Azure Container Registry with diagnostics logs, sends them to a Log Analytics workspace and with policies
DESCRIPTION: The following components will be options in this deployment
              Diagnostics
              Resource Lock
AUTHOR/S: bengeset96
VERSION: 1.0.0
*/

@minLength(5)
@maxLength(50)
@description('Azure Container Registry resource name')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

param dateModified string = utcNow('d')
var rgTags = resourceGroup().tags
var defaultResourceTags = {
  ModifiedDate: dateModified
}
param resourceTags object = {}
var tags = union(rgTags, resourceTags, defaultResourceTags)

@description('Azure Container Registry resource location will be based on the same location as resource group it will be deployed to')
param location string = resourceGroup().location

@description('Azure Container Registry service tier')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Enable system-assigned managed identity')
param enableSystemIdentity bool = false

@description('The list of user-assigned managed identity resource ids to associate with the Azure Container Registry')
@metadata({
  userAssignedIdentityResourceId: {}
})
param userAssignedIdentities object = {}

@description('Enable admin user on Azure Container Registry')
param enableAdminUser bool = false

@description('Enable public network access')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Enable zone redundancy, by default this is enabled so Azure Container Registry is minimum replicated across three seperate zones')
@allowed([
  'Disabled'
  'Enabled'
])
param zoneRedundancy string = 'Enabled'

@description('The network rule set for a container registry')
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
param ipRules object = {}

@description('Allow trusted Azure services to access restricted registry, by default this is none')
@allowed([
  'AzureServices'
  'None'
])
param networkRuleBypassOptions string = 'None'

@description('Azure Container Registry policies, by default qurantine and retention policy are enabled')
@metadata({
  exportPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are Enabled/Disabled'
  }
  quarantinePolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are Enabled/Disabled'
  }
  retentionPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are Enabled/Disabled'
    days: 'The number of days to retain an untagged manifest after which it gets purged'
  }
  trustPolicy: {
    status: 'The value that indicates whether the policy is enabled or not. Valid values are Enabled/Disabled'
  }
})
param policies object = {
  quarantinePolicy: {
    status: 'Enabled'
  }
  retentionPolicy: {
    status: 'Enabled'
    days: '30'
  }
}

@description('Enable delete lock, by default it is enabled')
param enableDeleteLock bool = true

@description('Enable diagnostic logs, by default it is enabled')
param enableDiagnostics bool = true

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true')
param logAnalyticsWorkspaceId string = ''

var lockName = '${acr.name}-lck'
var diagnosticsName = '${acr.name}-dgs'

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  tags: tags
  location: location
  sku: {
    name: acrSku
  }
  identity: enableSystemIdentity ? {
    type: 'SystemAssigned'
  } : !empty(userAssignedIdentities) ? {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  } : null
  properties: {
    adminUserEnabled: enableAdminUser
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancy
    networkRuleBypassOptions: networkRuleBypassOptions
    networkRuleSet: !empty(ipRules) ? {
      defaultAction: ipRules.defaultAction
      ipRules: ipRules.ipRules
      virtualNetworkRules: ipRules.virtualnetworkRules
    } : {}
    policies: policies
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: acr
  name: diagnosticsName
  properties: {
    workspaceId: empty(logAnalyticsWorkspaceId) ? null : logAnalyticsWorkspaceId
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

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: acr
  name: lockName
  properties: {
    level: 'CanNotDelete'
  }
}

// As you might can see, there is no Microsoft Defender for Containers resource declaration, this is because it should automatically be deployed by Microsoft Defender for Cloud
// It will do auto-provision of the required components

@description('Outputs from the module deployment that can be used for several handy scenarios')
output name string = acr.name
output id string = acr.id
output acrLoginServer string = acr.properties.loginServer
