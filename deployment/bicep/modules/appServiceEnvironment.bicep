param location string
param naming object

param vnetName string
param subnetName string

// Deploying this can take 3 hours
resource appServiceEnvironment 'Microsoft.Web/hostingEnvironments@2023-12-01' = {
  name: naming.appServiceEnvironment
  location: location
  kind: 'ASEV3'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    internalLoadBalancingMode: 'Web, Publishing'
    zoneRedundant: false
    networkingConfiguration: {
      properties: {
        ftpEnabled: false
        remoteDebugEnabled: false
      }
    }
    upgradePreference: 'Late'
    // dedicatedHostCount: 2
    // clusterSettings: [
    //   {
    //     // Slows down requests but more encryption (between front-ends and workers)
    //     name: 'InternalEncryption'
    //     value: 'true'
    //   }
    //   {
    //     // No TLS 1.0 or 1.1 (despite what the name says it also disables 1.1)
    //     name: 'DisableTls1.0'
    //     value: '1'
    //   }
    //   {
    //     // We only support these two cipher suites
    //     name: 'FrontEndSSLCipherSuiteOrder'
    //     value: 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
    //   }
    // ]
  }
}

output appServiceEnvironmentResourceId string = appServiceEnvironment.id
