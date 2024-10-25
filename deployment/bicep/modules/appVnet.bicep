param location string
param naming object

param sqlNsgResourceId string
param sqlRouteTableResourceId string

param addressSpace string
param hubAddressSpace string
param subnets object
param hubSubnets object
param firewallPrivateIpAddress string

// TODO: Add deny all inbound and outbound rules

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
        name: 'AllowVnetHttpsOutbound'
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
        name: 'AllowHubHttpsOutbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: hubAddressSpace
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowVnetSqlOutbound'
        properties: {
          priority: 300
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

resource createdSqlNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = if (empty(sqlNsgResourceId)) {
  name: 'nsg-app-${subnets.sql.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppServiceEnvironmentTdsInbound'
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
        name: 'AllowAppServiceEnvironmentRedirectInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.appServiceEnvironment.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '11000-11999'
        }
      }
      {
        name: 'AllowBuildAgentTdsInbound'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.buildAgent.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'AllowBuildAgentRedirectInbound'
        properties: {
          priority: 400
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnets.buildAgent.addressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '11000-11999'
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

// TODO: Fix SQL NSG and route table somehow
// Currently we get errors due to SQL MI adding routes and NSG rules and refusing their removal
// Need to check how these should be configured from some samples

resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = {
  name: naming.appVnetRouteTable
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'routeToFirewall'
        type: 'Microsoft.Network/routeTables/routes'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIpAddress
          hasBgpOverride: false
        }
      }
    ]
  }
}

resource createdSqlRouteTable 'Microsoft.Network/routeTables@2024-01-01' = if (empty(sqlRouteTableResourceId)) {
  name: naming.appVnetSqlRouteTable
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'routeToFirewall'
        type: 'Microsoft.Network/routeTables/routes'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIpAddress
          hasBgpOverride: false
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
          routeTable: {
            id: routeTable.id
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
          routeTable: {
            id: routeTable.id
          }
        }
      }
      {
        name: subnets.sql.name
        properties: {
          addressPrefix: subnets.sql.addressPrefix
          networkSecurityGroup: {
            id: empty(sqlNsgResourceId) ? createdSqlNsg.id : sqlNsgResourceId
          }
          routeTable: {
            id: empty(sqlRouteTableResourceId) ? createdSqlRouteTable.id : sqlRouteTableResourceId
          }
          delegations: [
            {
              name: 'Microsoft.Sql/managedInstances'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
      {
        name: subnets.appServiceKeyVault.name
        properties: {
          addressPrefix: subnets.appServiceKeyVault.addressPrefix
          networkSecurityGroup: {
            id: appServiceKeyVaultNsg.id
          }
          routeTable: {
            id: routeTable.id
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
          routeTable: {
            id: routeTable.id
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
          routeTable: {
            id: routeTable.id
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
          routeTable: {
            id: routeTable.id
          }
        }
      }
      {
        name: subnets.buildAgent.name
        properties: {
          addressPrefix: subnets.buildAgent.addressPrefix
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
}

// TODO: NSGs, route tables, DNS
output vnetResourceId string = vnet.id
