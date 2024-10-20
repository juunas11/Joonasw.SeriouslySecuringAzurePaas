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
      appSettings: []
      alwaysOn: true
      ftpsState: 'Disabled'
      // We could require 1.3 and a higher minimum cipher suite,
      // but it feels a bit excessive.
      // This is still within best practices.
      minTlsVersion: '1.2'
      minTlsCipherSuite: 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
      remoteDebuggingEnabled: false
      scmMinTlsVersion: '1.2'
    }
  }
}

output webAppFqdn string = webApp.properties.defaultHostName
