param location string = resourceGroup().location

var suffix = uniqueString(resourceGroup().id)
var naming = {
  appGateway: 'agw-${suffix}'
  appServiceEnvironment: 'ase-${suffix}'
  appServicePlan: 'asp-${suffix}'
  appVnet: 'vnet-app-${suffix}'
  hubVnet: 'vnet-hub-${suffix}'
  firewall: 'afw-${suffix}'
  firewallPip: 'pip-afw-${suffix}'
  firewallManagementPip: 'pip-afw-mgmt-${suffix}'
  firewallPolicy: 'afw-policy-${suffix}'
  wafPolicy: 'waf-policy-${suffix}'
}

var vnetAddressSpaces = {
  hub: '10.0.0.0/22'
  app: '10.0.4.0/22'
}

var hubSubnets = {
  firewall: {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.0.0.0/24'
  }
  firewallManagement: {
    name: 'AzureFirewallManagementSubnet'
    addressPrefix: '10.0.1.0/24'
  }
}
var appSubnets = {
  appGateway: {
    name: 'appGateway'
    addressPrefix: '10.0.4.0/26'
  }
  appServiceEnvironment: {
    name: 'appServiceEnvironment'
    addressPrefix: '10.0.4.64/26'
  }
  sql: {
    name: 'sql'
    addressPrefix: '10.0.4.128/26'
  }
  appServiceKeyVault: {
    name: 'appServiceKeyVault'
    addressPrefix: '10.0.4.192/26'
  }
  storage: {
    name: 'storage'
    addressPrefix: '10.0.5.0/26'
  }
  sqlKeyVault: {
    name: 'sqlKeyVault'
    addressPrefix: '10.0.5.64/26'
  }
  storageKeyVault: {
    name: 'storageKeyVault'
    addressPrefix: '10.0.5.128/26'
  }
}
var appGatewayPrivateIpAddress = '10.0.4.4'

module hubVnet 'modules/hubVnet.bicep' = {
  name: '${deployment().name}-hubVnet'
  params: {
    location: location
    naming: naming
    addressSpace: vnetAddressSpaces.hub
    subnets: hubSubnets
  }
}

// module firewall 'modules/firewall.bicep' = {
//   name: 'firewall'
//   params: {
//     location: location
//     naming: naming
//     firewallSubnetResourceId: hubVnet.outputs.firewallSubnetResourceId
//     firewallManagementSubnetResourceId: hubVnet.outputs.firewallManagementSubnetResourceId
//   }
// }

module appVnet 'modules/appVnet.bicep' = {
  name: '${deployment().name}-appVnet'
  params: {
    location: location
    naming: naming
    addressSpace: vnetAddressSpaces.app
    subnets: appSubnets
  }
}

module appHubPeering 'modules/vnetPeering.bicep' = {
  name: '${deployment().name}-appHubPeering'
  params: {
    hubVnetName: naming.hubVnet
    spokeVnetName: naming.appVnet
  }
  dependsOn: [
    appVnet
    hubVnet
  ]
}

module appGatewayWaf 'modules/appGatewayWaf.bicep' = {
  name: '${deployment().name}-appGatewayWaf'
  params: {
    location: location
    naming: naming
    vnetName: naming.appVnet
    appGatewaySubnetName: appSubnets.appGateway.name
    appGatewayPrivateIpAddress: appGatewayPrivateIpAddress
  }
  dependsOn: [
    appVnet
  ]
}

module appServiceEnvironment 'modules/appServiceEnvironment.bicep' = {
  name: '${deployment().name}-appServiceEnvironment'
  params: {
    location: location
    naming: naming
    vnetName: naming.appVnet
    subnetName: appSubnets.appServiceEnvironment.name
  }
  dependsOn: [
    appVnet
  ]
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: '${deployment().name}-appServicePlan'
  params: {
    location: location
    naming: naming
    appServiceEnvironmentResourceId: appServiceEnvironment.outputs.appServiceEnvironmentResourceId
  }
}

module webApp 'modules/webApp.bicep' = {
  name: '${deployment().name}-webApp'
  params: {
    location: location
    naming: naming
    appServiceEnvironmentResourceId: appServiceEnvironment.outputs.appServiceEnvironmentResourceId
    appServicePlanResourceId: appServicePlan.outputs.appServicePlanResourceId
  }
}
