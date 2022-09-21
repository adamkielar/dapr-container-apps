param keyVaultId string
param serviceBusId string
param redisCacheId string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: last(split(serviceBusId, '/'))
  scope: resourceGroup(split(serviceBusId, '/')[4])

  resource sharedAccessKey 'AuthorizationRules' existing = {
    name: 'DefaultAuthorizationRule'
  }
}

resource redisCache 'Microsoft.Cache/redis@2022-05-01' existing = {
  name: last(split(redisCacheId, '/'))
  scope: resourceGroup(split(redisCacheId, '/')[4])
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: last(split(keyVaultId, '/'))

  resource secretServiceBusPrimaryKey 'secrets' = {
    name: 'serviceBusKey'
    properties: {
      value: serviceBus::sharedAccessKey.listKeys().primaryKey
    }
  }
  resource secretServiceBusConnectionString 'secrets' = {
    name: 'serviceBusConnectionString'
    properties: {
      value: serviceBus::sharedAccessKey.listKeys().primaryConnectionString
    }
  }
  resource secretRedisCachePrimaryKey 'secrets' = {
    name: 'redisCacheKey'
    properties: {
      value: redisCache.listKeys().primaryKey
    }
  }
  resource secretRedisCacheHost 'secrets' = {
    name: 'redisCacheHost'
    properties: {
      value: '${redisCache.name}.redis.cache.windows.net:6380'
    }
  }
}
