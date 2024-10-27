param location string
param naming object

param sqlNsgResourceId string
param sqlRouteTableResourceId string

param addressSpace string
param hubAddressSpace string
param subnets object
param hubSubnets object
param firewallPrivateIpAddress string

param devOpsInfrastructureSpId string

var denyAllInboundRule = {
  name: 'DenyAllInbound'
  properties: {
    priority: 4096
    direction: 'Inbound'
    access: 'Deny'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
  }
}
var denyAllOutboundRule = {
  name: 'DenyAllOutbound'
  properties: {
    priority: 4096
    direction: 'Outbound'
    access: 'Deny'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
  }
}

resource appServiceEnvironmentNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.appServiceEnvironment.name}'
  location: location
  properties: {
    securityRules: [
      // {
      //   name: 'AllowAppGatewayHttpsInbound'
      //   properties: {
      //     priority: 100
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: subnets.appGateway.addressPrefix
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '443'
      //   }
      // }
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
        // Internal health pings
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      denyAllInboundRule
      // {
      //   name: 'AllowVnetHttpsOutbound'
      //   properties: {
      //     priority: 100
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: 'VirtualNetwork'
      //     destinationPortRange: '443'
      //   }
      // }
      // {
      //   name: 'AllowHubHttpsOutbound'
      //   properties: {
      //     priority: 200
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: hubAddressSpace
      //     destinationPortRange: '443'
      //   }
      // }
      // {
      //   name: 'AllowVnetSqlOutbound'
      //   properties: {
      //     priority: 300
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: 'VirtualNetwork'
      //     destinationPortRange: '1433'
      //   }
      // }
      denyAllOutboundRule
    ]
  }
}

resource webAppInboundNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.webAppInbound.name}'
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
      denyAllInboundRule
      denyAllOutboundRule
    ]
  }
}

resource webAppOutboundNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.webAppOutbound.name}'
  location: location
  properties: {
    securityRules: [
      denyAllInboundRule
      {
        name: 'AllowMonitorHttpsOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: hubSubnets.monitor.addressPrefix
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowSqlTdsOutbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: subnets.sql.addressPrefix
          destinationPortRange: '1433'
        }
      }
      denyAllOutboundRule
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
      // Azure Load Balancer must be allowed for App Gateway v2 SKU
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      denyAllInboundRule
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
      denyAllOutboundRule
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
      denyAllInboundRule
      denyAllOutboundRule
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
      denyAllInboundRule
      denyAllOutboundRule
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
      denyAllInboundRule
      denyAllOutboundRule
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
      denyAllInboundRule
      denyAllOutboundRule
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
      denyAllInboundRule
      denyAllOutboundRule
    ]
  }
}

resource buildAgentNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.buildAgent.name}'
  location: location
  properties: {
    securityRules: [
      denyAllInboundRule
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
      {
        name: 'DenyVnetOutbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: addressSpace
          destinationPortRange: '*'
        }
      }
      // Allow traffic destined out of the VNET
    ]
  }
}

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
        name: subnets.webAppInbound.name
        properties: {
          addressPrefix: subnets.webAppInbound.addressPrefix
          networkSecurityGroup: {
            id: webAppInboundNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
        }
      }
      {
        name: subnets.webAppOutbound.name
        properties: {
          addressPrefix: subnets.webAppOutbound.addressPrefix
          networkSecurityGroup: {
            id: webAppOutboundNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
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
          networkSecurityGroup: {
            id: buildAgentNsg.id
          }
          delegations: [
            {
              name: 'Microsoft.DevOpsInfrastructure/pools'
              properties: {
                serviceName: 'Microsoft.DevOpsInfrastructure/pools'
              }
            }
          ]
        }
      }
    ]
  }
}

resource devOpsInfrastructureReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(devOpsInfrastructureSpId, vnet.id, 'Reader')
  scope: vnet
  properties: {
    principalId: devOpsInfrastructureSpId
    principalType: 'ServicePrincipal'
    // Reader role
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    )
  }
}

resource devOpsInfrastructureNetworkContibutorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(devOpsInfrastructureSpId, vnet.id, 'Network Contributor')
  scope: vnet
  properties: {
    principalId: devOpsInfrastructureSpId
    principalType: 'ServicePrincipal'
    // Network Contributor role
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4d97b98b-1d4f-4787-a291-c67834d212e7'
    )
  }
}

output vnetResourceId string = vnet.id
