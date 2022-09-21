param projectName string
param location string
param pythonReceiverApp string = 'python-receiver'
param logName string = '${projectName}-logs'
param envName string = '${projectName}-env'
param appInsightsName string = '${projectName}-ai'
param vnet object

@secure()
param redisCacheKey string
@secure()
param redisCacheHost string

// ============== //
// Log Analytics
// ============== //

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logName
  location: location
}

// ============== //
// App Insights
// ============== //

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:logAnalyticsWorkspace.id
  }
}

// ============== //
// Container App Environment
// ============== //

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIConnectionString: appInsights.properties.ConnectionString
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    vnetConfiguration: {
      dockerBridgeCidr: '100.64.0.1/16'
      infrastructureSubnetId: vnet.infrastructureSubnetId
      internal: false
      platformReservedCidr: '198.18.0.0/16'
      platformReservedDnsIP: '198.18.0.10'
      runtimeSubnetId: vnet.runtimeSubnetId
    }
  }
  resource daprComponent 'daprComponents' = {
    name: 'statestore'
    properties: {
      componentType: 'state.redis'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5s'
      secrets: [
        {
          name: 'redisCacheKey'
          value: redisCacheKey
        }
        {
          name: 'redisCacheHost'
          value: redisCacheHost
        }
      ]
      metadata: [
        {
          name: 'redisHost'
          secretRef: 'redisCacheHost'
        }
        {
          name: 'redisPassword'
          secretRef: 'redisCacheKey'
        }
        {
          name: 'actorStateStore'
          value: 'true'
        }
      ]
      scopes: [
        pythonReceiverApp
      ]
    }
  }
}

output environmentId string = containerAppsEnvironment.id
