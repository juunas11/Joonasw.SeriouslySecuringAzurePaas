param location string
param naming object

param addressSpace string
param subnets object
param hubSubnets object

resource appServiceEnvironmentNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.appServiceEnvironment.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppGatewayHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.appGateway.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBuildAgentHttpsInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.buildAgent.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowVnetHttpsOutBound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowVnetSqlOutBound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '1433'
        }
      }
    ]
  }
}

resource appGatewayNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.appGateway.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowFirewallHttpInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: hubSubnets.firewall.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'AllowFirewallHttpsInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: hubSubnets.firewall.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAppServiceEnvironmentHttpsOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: subnets.appServiceEnvironment.addressPrefix
          destinationPortRange: '443'
        }
      }
    ]
  }
}

resource sqlNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.sql.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppServiceEnvironmentSqlInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.appServiceEnvironment.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'AllowBuildAgentSqlInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.buildAgent.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
    ]
  }
}

resource appServiceKeyVaultNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.appServiceKeyVault.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppServiceEnvironmentHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.appServiceEnvironment.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      // TODO: Let's see if this is needed
      // {
      //   name: 'AllowBuildAgentHttpsInbound'
      //   properties: {
      //     priority: 200
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: subnets.buildAgent.addressPrefix
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '443'
      //   }
      // }
    ]
  }
}

resource storageNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.storage.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppServiceEnvironmentHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.appServiceEnvironment.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      // TODO: Let's see if this is needed
      // {
      //   name: 'AllowBuildAgentHttpsInbound'
      //   properties: {
      //     priority: 200
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: subnets.buildAgent.addressPrefix
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '443'
      //   }
      // }
    ]
  }
}

resource sqlKeyVaultNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.sqlKeyVault.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSqlHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.sql.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      // TODO: Build agent?
    ]
  }
}

resource storageKeyVaultNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.storageKeyVault.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowStorageHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.storage.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: naming.appVnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: subnets.appServiceEnvironment.name
        properties: {
          addressPrefix: subnets.appServiceEnvironment.addressPrefix
          networkSecurityGroup: {
            id: appServiceEnvironmentNsg.id
          }
          delegations: [
            {
              name: 'Microsoft.Web/hostingEnvironments'
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
      {
        name: subnets.appGateway.name
        properties: {
          addressPrefix: subnets.appGateway.addressPrefix
          networkSecurityGroup: {
            id: appGatewayNsg.id
          }
        }
      }
      {
        name: subnets.sql.name
        properties: {
          addressPrefix: subnets.sql.addressPrefix
          networkSecurityGroup: {
            id: sqlNsg.id
          }
        }
      }
      {
        name: subnets.appServiceKeyVault.name
        properties: {
          addressPrefix: subnets.appServiceKeyVault.addressPrefix
          networkSecurityGroup: {
            id: appServiceKeyVaultNsg.id
          }
        }
      }
      {
        name: subnets.storage.name
        properties: {
          addressPrefix: subnets.storage.addressPrefix
          networkSecurityGroup: {
            id: storageNsg.id
          }
        }
      }
      {
        name: subnets.sqlKeyVault.name
        properties: {
          addressPrefix: subnets.sqlKeyVault.addressPrefix
          networkSecurityGroup: {
            id: sqlKeyVaultNsg.id
          }
        }
      }
      {
        name: subnets.storageKeyVault.name
        properties: {
          addressPrefix: subnets.storageKeyVault.addressPrefix
          networkSecurityGroup: {
            id: storageKeyVaultNsg.id
          }
        }
      }
    ]
  }
}

// TODO: NSGs, route tables, DNS
output vnetResourceId string = vnet.id
