param privateEndpointName string
param location string
param redisCacheName string
param subnetId string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: split(subnetId, '/')[8]

  resource subnet 'subnets' existing = {
    name: last(split(subnetId, '/'))
  }
}

resource redisCache 'Microsoft.Cache/redis@2022-05-01' existing = {
  name: redisCacheName
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'

  resource virtualNetworkLinks 'virtualNetworkLinks' = {
    name: uniqueString(vnet.id, redisCache.name)
    location: 'global'
    properties: {
      virtualNetwork: {
        id: vnet.id
      }
      registrationEnabled: false
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  dependsOn: [
    privateDns::virtualNetworkLinks
  ]
  properties: {
    subnet: {
      id: vnet::subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
  }

  resource zoneConfig 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: replace(privateDns.name, '.', '-')
          properties: {
            privateDnsZoneId: privateDns.id
          }
        }
      ]
    }
  }
}
