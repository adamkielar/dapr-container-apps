param projectName string
param location string = resourceGroup().location

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

module containerAppsEnvironment 'environment.bicep' = {
  name: '${_deployment}-env'
  params: {
    projectName: projectName
    location: location
    vnet: {
      infrastructureSubnetId: vnet.properties.subnets[1].id
      runtimeSubnetId: vnet.properties.subnets[2].id
    }
  }
}
