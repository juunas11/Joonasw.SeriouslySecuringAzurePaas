param location string = resourceGroup().location

param sqlAdminGroupName string
param sqlAdminGroupId string

@secure()
param appGatewayCertificateData string
@secure()
param appGatewayCertificatePassword string

param sqlNsgResourceId string
param sqlRouteTableResourceId string

param azureDevOpsOrganizationUrl string
param azureDevOpsProjectName string
param devCenterProjectResourceId string

param devOpsInfrastructureSpId string

var suffix = uniqueString(resourceGroup().id)
var naming = {
  appGateway: 'agw-${suffix}'
  appInsights: 'ai-${suffix}'
  appServiceEnvironment: 'ase-${suffix}'
  appServicePlan: 'asp-${suffix}'
  appVnet: 'vnet-app-${suffix}'
  appVnetRouteTable: 'rt-app-${suffix}'
  appVnetSqlRouteTable: 'rt-app-sql-${suffix}'
  buildAgentPool: 'devops-pool-${suffix}'
  firewall: 'afw-${suffix}'
  firewallManagementPip: 'pip-afw-mgmt-${suffix}'
  firewallPip: 'pip-afw-${suffix}'
  firewallPolicy: 'afw-policy-${suffix}'
  keyVault: 'kv-${suffix}'
  keyVaultPrivateEndpoint: 'kv-pe-${suffix}'
  hubVnet: 'vnet-hub-${suffix}'
  logAnalytics: 'law-${suffix}'
  logAnalyticsPrivateEndpoint: 'law-pe-${suffix}'
  logAnalyticsPrivateLinkScope: 'law-pls-${suffix}'
  sqlManagedInstance: 'sql-${suffix}'
  storageAccount: 'sa${suffix}'
  storageAccountPrivateEndpoint: 'sa-pe-blob-${suffix}'
  storageWebAppAuthenticationContainer: 'webappauth'
  wafPolicy: 'waf-policy-${suffix}'
  webApp: 'app-${suffix}'
  webAppPrivateEndpoint: 'app-pe-${suffix}'
}

var vnetAddressSpaces = {
  hub: '10.0.0.0/22' // 10.0.0.0 - 10.0.3.255
  app: '10.0.4.0/22' // 10.0.4.0 - 10.0.7.255
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
  monitor: {
    name: 'monitor'
    addressPrefix: '10.0.2.0/26'
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
  webAppInbound: {
    name: 'webAppInbound'
    addressPrefix: '10.0.4.128/26'
  }
  webAppOutbound: {
    name: 'webAppOutbound'
    addressPrefix: '10.0.4.192/26'
  }
  sql: {
    name: 'sql'
    addressPrefix: '10.0.5.0/26'
  }
  appServiceKeyVault: {
    name: 'appServiceKeyVault'
    addressPrefix: '10.0.5.64/26'
  }
  storage: {
    name: 'storage'
    addressPrefix: '10.0.5.128/26'
  }
  sqlKeyVault: {
    name: 'sqlKeyVault'
    addressPrefix: '10.0.5.192/26'
  }
  storageKeyVault: {
    name: 'storageKeyVault'
    addressPrefix: '10.0.6.0/26'
  }
  buildAgent: {
    name: 'buildAgent'
    addressPrefix: '10.0.6.64/26'
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
    appVnetAddressSpace: vnetAddressSpaces.app
  }
}

module firewall 'modules/firewall.bicep' = {
  name: '${deployment().name}-firewall'
  params: {
    location: location
    naming: naming
    firewallSubnetResourceId: hubVnet.outputs.firewallSubnetResourceId
    firewallManagementSubnetResourceId: hubVnet.outputs.firewallManagementSubnetResourceId
    appGatewayPrivateIpAddress: appGatewayPrivateIpAddress
    appSubnets: appSubnets
  }
}

module appVnet 'modules/appVnet.bicep' = {
  name: '${deployment().name}-appVnet'
  params: {
    location: location
    naming: naming
    addressSpace: vnetAddressSpaces.app
    hubAddressSpace: vnetAddressSpaces.hub
    subnets: appSubnets
    hubSubnets: hubSubnets
    firewallPrivateIpAddress: firewall.outputs.firewallPrivateIpAddress
    sqlNsgResourceId: sqlNsgResourceId
    sqlRouteTableResourceId: sqlRouteTableResourceId
    devOpsInfrastructureSpId: devOpsInfrastructureSpId
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

module commonPrivateDns 'modules/commonPrivateDns.bicep' = {
  name: '${deployment().name}-commonPrivateDns'
  params: {
    hubVnetResourceId: hubVnet.outputs.vnetResourceId
    appVnetResourceId: appVnet.outputs.vnetResourceId
  }
}

module monitor 'modules/monitor.bicep' = {
  name: '${deployment().name}-monitor'
  params: {
    location: location
    naming: naming
    privateEndpointVnetName: naming.hubVnet
    privateEndpointSubnetName: hubSubnets.monitor.name
    hubVnetResourceId: hubVnet.outputs.vnetResourceId
    appVnetResourceId: appVnet.outputs.vnetResourceId
    storageBlobDnsZoneResourceId: commonPrivateDns.outputs.storageBlobDnsZoneResourceId
  }
  dependsOn: [
    hubVnet
  ]
}

module sql 'modules/sql.bicep' = {
  name: '${deployment().name}-sql'
  params: {
    location: location
    naming: naming
    vnetName: naming.appVnet
    subnetName: appSubnets.sql.name
    adminGroupName: sqlAdminGroupName
    adminGroupId: sqlAdminGroupId
  }
  dependsOn: [
    appVnet
  ]
}

module buildAgent 'modules/buildAgent.bicep' = {
  name: '${deployment().name}-buildAgent'
  params: {
    location: location
    naming: naming
    vnetName: naming.appVnet
    subnetName: appSubnets.buildAgent.name
    azureDevOpsOrganizationUrl: azureDevOpsOrganizationUrl
    azureDevOpsProjectName: azureDevOpsProjectName
    devCenterProjectResourceId: devCenterProjectResourceId
  }
  dependsOn: [
    appVnet
  ]
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${deployment().name}-keyVault'
  params: {
    location: location
    naming: naming
    keyVaultPrivateDnsZoneId: commonPrivateDns.outputs.keyVaultDnsZoneResourceId
    privateEndpointVnetName: naming.appVnet
    privateEndpointSubnetName: appSubnets.appServiceKeyVault.name
  }
  dependsOn: [
    appVnet
  ]
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: '${deployment().name}-storageAccount'
  params: {
    location: location
    naming: naming
    privateEndpointVnetName: naming.appVnet
    privateEndpointSubnetName: appSubnets.storage.name
    storageBlobPrivateDnsZoneId: commonPrivateDns.outputs.storageBlobDnsZoneResourceId
  }
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
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    storageAccountResourceId: storageAccount.outputs.storageAccountResourceId
    subnets: appSubnets
    // appServiceEnvironmentDnsZoneResourceId: commonPrivateDns.outputs.appServiceEnvironmentDnsZoneResourceId
    // appServiceEnvironmentIpAddress: appServiceEnvironment.outputs.appServiceEnvironmentIpAddress
    appVnetName: naming.appVnet
    appServiceDnsZoneResourceId: commonPrivateDns.outputs.appServiceDnsZoneResourceId
  }
}

module appGatewayWaf 'modules/appGatewayWaf.bicep' = {
  name: '${deployment().name}-appGatewayWaf'
  params: {
    location: location
    naming: naming
    vnetName: naming.appVnet
    appGatewaySubnetName: appSubnets.appGateway.name
    appGatewayPrivateIpAddress: appGatewayPrivateIpAddress
    certificateData: appGatewayCertificateData
    certificatePassword: appGatewayCertificatePassword
    webAppFqdn: webApp.outputs.webAppFqdn
  }
  dependsOn: [
    appVnet
  ]
}

output firewallPublicIpAddress string = firewall.outputs.firewallPublicIpAddress
output sqlManagedInstanceIdentityObjectId string = sql.outputs.sqlManagedInstanceIdentityObjectId
