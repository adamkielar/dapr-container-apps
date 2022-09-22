param projectName string = 'dapr-containerapp'
param acrServer string
param containerAppName string
param externalIngressEnabled bool = false
param containerImage string
param containerPort int
param location string = resourceGroup().location


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
        appProtocol: 'http'
        appId: containerAppName
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
          probes: [
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
              periodSeconds: 3
            }
            {
              type: 'Readiness'
              tcpSocket: {
                port: containerPort
              }
              initialDelaySeconds: 10
              periodSeconds: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
