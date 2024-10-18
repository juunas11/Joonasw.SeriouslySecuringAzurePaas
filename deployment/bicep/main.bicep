param location string = resourceGroup().location

var naming = {

}

var vnetAddressSpaces = {
  hub: '10.0.0.0/22'
  app: '10.0.4.0/22'
}

var hubSubnets = {
  firewall: '10.0.0.0/24'
}
var appSubnets = {
  appGateway: '10.0.4.0/26'
  appServiceEnvironment: '10.0.4.64/26'
  sql: '10.0.4.128/26'
  appServiceKeyVault: '10.0.4.192/26'
  storage: '10.0.5.0/26'
  sqlKeyVault: '10.0.5.64/26'
  storageKeyVault: '10.0.5.128/26'
}

module hubVnet 'modules/hubVnet.bicep' = {
  name: 'hubVnet'
  params: {
    location: location
    naming: naming
    vnetAddressSpaces: vnetAddressSpaces
  }
}

module appVnet 'modules/appVnet.bicep' = {
  name: 'appVnet'
  params: {
    location: location
    naming: naming
    vnetAddressSpaces: vnetAddressSpaces
  }
}
