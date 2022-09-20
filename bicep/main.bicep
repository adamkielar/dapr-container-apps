param projectName string
param location string = resourceGroup().location

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
  {
    name: 'redis-snet'
    addressPrefix: '10.0.6.0/26'
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
  'redis-snet': vnet.properties.subnets[3].id
}

// ============== //
// ACR
// ============== //
resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: '${projectNameSafe}acr'
  location: location
  sku: {
    name: 'Basic'
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
    acrName: acr.name
    subnetId: vnetSubnets['core-snet']
  }
}

// ============== //
// Container App Environment
// ============== //

module containerAppsEnvironment 'environment.bicep' = {
  name: '${_deployment}-env'
  params: {
    projectName: projectName
    location: location
    vnet: {
      infrastructureSubnetId: vnetSubnets['infrastructure-snet']
      runtimeSubnetId: vnetSubnets['runtime-snet']
    }
  }
}
