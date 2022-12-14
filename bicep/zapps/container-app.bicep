param projectName string
param acrServer string
param containerAppName string
param externalIngressEnabled bool
param containerProbesEnabled bool
param containerImage string
param containerPort int
param appProtocol string
param location string

@secure()
param redisCacheKey string
@secure()
param redisCacheHost string
@secure()
param serviceBusConnectionString string


resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: '${projectName}-id'
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: '${projectName}-env'
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'redis-cache-key'
          value: redisCacheKey
        }
        {
          name: 'redis-cache-host'
          value: redisCacheHost
        }
        {
          name: 'sb-root-connectionstring'
          value: serviceBusConnectionString
        }
      ]
      registries: [
        {
          server: acrServer
          identity: appIdentity.id
        }
      ]
      ingress: {
        external: externalIngressEnabled
        targetPort: containerPort
      }
      dapr: {
        enabled: true
        appPort: containerPort
        appProtocol: appProtocol
        appId: containerAppName
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: [
            {
              name: 'redisHost'
              secretRef: 'redis-cache-host'
            }
            {
              name: 'redisPassword'
              secretRef: 'redis-cache-key'
            }
            {
              name: 'connectionString'
              secretRef: 'sb-root-connectionstring'
            }
          ]
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
          probes: containerProbesEnabled ? [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: containerPort
                httpHeaders: [
                  {
                    name: 'Custom-Header'
                    value: 'liveness probe'
                  }
                ]
              }
              initialDelaySeconds: 7
              periodSeconds: 5
            }
            {
              type: 'Readiness'
              tcpSocket: {
                port: containerPort
              }
              initialDelaySeconds: 10
              periodSeconds: 5
            }
          ] : []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
