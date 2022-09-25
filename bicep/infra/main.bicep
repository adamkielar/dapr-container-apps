param projectName string
param location string = resourceGroup().location
param serviceBusTopicName string

var projectNameSafe = toLower(replace(projectName, '-', ''))
var _deployment = deployment().name
var _subnets = [
  {
    name: 'core-snet'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'infrastructure-snet'
    addressPrefix: '10.0.2.0/23'
  }
  {
    name: 'runtime-snet'
    addressPrefix: '10.0.4.0/23'
  }
]

// ============== //
// Vnet           //
// ============== //

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${projectName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [for item in _subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
      }
    }]
  }
}

var vnetSubnets = {
  'core-snet': vnet.properties.subnets[0].id
  'infrastructure-snet': vnet.properties.subnets[1].id
  'runtime-snet': vnet.properties.subnets[2].id
}

// ============== //
// User-assigned Identity For Container Apps
// ============== //

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${projectName}-id'
  location: location
}

// ============== //
// ACR
// ============== //

resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: '${projectNameSafe}acr'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
  }
}

module privateEndpointAcr 'acr-privatelink.bicep' = {
  name: '${_deployment}-acr-pe'
  params: {
    privateEndpointName: '${projectName}-acr-pe'
    location: location
    acrId: acr.id
    subnetId: vnetSubnets['core-snet']
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(acr.name, 'AcrPull', appIdentity.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: appIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ============== //
// Key Vault
// ============== //

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: '${projectName}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
  }
}

module privateEndpointKeyVault 'keyvault-privatelink.bicep' = {
  name: '${_deployment}-kv-pe'
  params: {
    privateEndpointName: '${projectName}-kv-pe'
    location: location
    keyVaultId: keyVault.id
    subnetId: vnetSubnets['core-snet']
  }
}

resource kvSecretUserRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(keyVault.name, 'Key Vault Secrets User', appIdentity.id)
  scope: keyVault
  properties: {
    principalId: appIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

module secrets 'keyvault-secrets.bicep' = {
  name: '${_deployment}-kv-secrets'
  params: {
    keyVaultId: keyVault.id
    serviceBusId: serviceBusNamespace.id
    redisCacheId: redisCache.id
  }
}
// ============== //
// Redis Cache
// ============== //

resource redisCache 'Microsoft.Cache/redis@2022-05-01' = {
  name: '${projectName}-redis'
  location: location
  properties: {
    enableNonSslPort: true
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisVersion: '6'
    sku: {
      capacity: 0
      family: 'C'
      name: 'Basic'
    }
  }
}

module privateEndpointRedisCache 'redis-privatelink.bicep' = {
  name: '${_deployment}-redis-pe'
  params: {
    privateEndpointName: '${projectName}-redis-pe'
    location: location
    redisCacheId: redisCache.id
    subnetId: vnetSubnets['core-snet']
  }
}

// ============== //
// Service Bus
// ============== //
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: '${projectName}-sbn'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}

  resource sharedAccessKey 'AuthorizationRules' = {
    name: 'DefaultAuthorizationRule'
    properties: {
      rights: [
        'Manage'
        'Listen'
        'Send'
      ]
    }
  }
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: serviceBusTopicName
  properties: {
    maxSizeInMegabytes: 1024
    supportOrdering: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    requiresDuplicateDetection: false
  }
}

// ============== //
// Container App Environment
// ============== //

module containerAppsEnvironment 'environment.bicep' = {
  dependsOn: [
    secrets
  ]
  name: '${_deployment}-env'
  params: {
    projectName: projectName
    redisCacheKey: keyVault.getSecret('redisCacheKey')
    redisCacheHost: keyVault.getSecret('redisCacheHost')
    serviceBusConnectionString: keyVault.getSecret('serviceBusConnectionString')
    location: location
    vnet: {
      infrastructureSubnetId: vnetSubnets['infrastructure-snet']
      runtimeSubnetId: vnetSubnets['runtime-snet']
    }
  }
}
