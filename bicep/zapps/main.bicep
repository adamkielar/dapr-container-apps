param projectName string = 'dapr-containerapp'
param acrServer string
param containerAppName string
param externalIngressEnabled bool = false
param containerProbesEnabled bool = true
param containerImage string
param containerPort int
param appProtocol string = 'http'
param location string = resourceGroup().location

var _deployment = deployment().name

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: '${projectName}-kv'
}

module containerApps 'container-app.bicep' = {
  name: '${_deployment}-apps'
  params: {
    projectName: projectName
    redisCacheKey: keyVault.getSecret('redisCacheKey')
    redisCacheHost: keyVault.getSecret('redisCacheHost')
    serviceBusConnectionString: keyVault.getSecret('serviceBusConnectionString')
    acrServer: acrServer
    containerAppName: containerAppName
    externalIngressEnabled: externalIngressEnabled
    containerProbesEnabled: containerProbesEnabled
    containerImage: containerImage
    containerPort: containerPort
    appProtocol: appProtocol
    location: location
  }
}
