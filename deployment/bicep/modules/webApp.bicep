param location string
param naming object

param appServiceEnvironmentResourceId string
param appServicePlanResourceId string

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: naming.webApp
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanResourceId
    hostingEnvironmentProfile: {
      id: appServiceEnvironmentResourceId
    }
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    siteConfig: {
      appSettings: [
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.3'
      minTlsCipherSuite: 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
      remoteDebuggingEnabled: false
      scmMinTlsVersion: '1.3'
    }
  }
}
