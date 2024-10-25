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
    clusterSettings: [
      {
        // Slows down requests but adds encryption between front-ends and workers
        name: 'InternalEncryption'
        value: 'true'
      }
      {
        // No TLS 1.0 or 1.1 (despite what the name says it also disables 1.1)
        name: 'DisableTls1.0'
        value: '1'
      }
    ]

    // Run on dedicated hardware, costs a lot more
    // dedicatedHostCount: 2
  }
}

module appServiceEnvironmentDns './appServiceEnvironmentDns.bicep' = {
  name: 'appServiceEnvironmentDns'
  params: {
    location: location
    appServiceEnvironmentDnsSuffix: appServiceEnvironment.properties.dnsSuffix
    // TODO: Check this, could be wrong
    appServiceEnvironmentIpAddress: appServiceEnvironment.properties.networkingConfiguration.properties.internalInboundIpAddresses[0]
  }
}

output appServiceEnvironmentResourceId string = appServiceEnvironment.id
