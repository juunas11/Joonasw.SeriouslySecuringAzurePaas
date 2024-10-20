param location string
param naming object

param vnetName string
param subnetName string

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
  }
}

output appServiceEnvironmentResourceId string = appServiceEnvironment.id
