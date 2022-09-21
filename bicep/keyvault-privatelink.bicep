param privateEndpointName string
param location string
param keyVaultId string
param subnetId string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: split(subnetId, '/')[8]

  resource subnet 'subnets' existing = {
    name: last(split(subnetId, '/'))
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'

  resource virtualNetworkLinks 'virtualNetworkLinks' = {
    name: uniqueString(vnet.id, keyVault.name)
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
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
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
