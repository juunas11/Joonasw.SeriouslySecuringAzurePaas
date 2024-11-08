param location string
param naming object

param sqlNsgResourceId string
param sqlRouteTableResourceId string

param addressSpace string
// param hubAddressSpace string
param subnets object
param hubSubnets object
param firewallPrivateIpAddress string

param devOpsInfrastructureSpId string

param developerIpAddress string

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
var allowManagementVmInboundRule = {
  name: 'AllowManagementVmAnyInbound'
  properties: {
    priority: 4095
    direction: 'Inbound'
    access: 'Allow'
    protocol: '*'
    sourceAddressPrefix: subnets.managementVm.addressPrefix
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
      // TODO: Fix issues with NSG / Route table so they can be re-enabled
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
      allowManagementVmInboundRule
      // TODO: Check logs for this and the outbound rule to see if it is working (ASE did deploy and function without these too even though there was blocks in logs)
      // {
      //   name: 'AllowInternalInbound'
      //   properties: {
      //     priority: 400
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '172.16.0.0/12'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '*'
      //   }
      // }
      denyAllInboundRule
      // {
      //   name: 'AllowInternalOutbound'
      //   properties: {
      //     priority: 100
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '172.16.0.0/12'
      //     destinationPortRange: '*'
      //   }
      // }
      // TODO: Let's see can we limit outbound traffic
      // {
      //   name: 'AllowMonitorHttpsOutbound'
      //   properties: {
      //     priority: 100
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: hubSubnets.monitor.addressPrefix
      //     destinationPortRange: '443'
      //   }
      // }
      // {
      //   name: 'AllowSqlTdsOutbound'
      //   properties: {
      //     priority: 200
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: subnets.sql.addressPrefix
      //     destinationPortRange: '1433'
      //   }
      // }
      // {
      //   name: 'AllowManagedHsmHttpsOutbound'
      //   properties: {
      //     priority: 300
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: subnets.appServiceManagedHsm.addressPrefix
      //     destinationPortRange: '443'
      //   }
      // }
      // {
      //   name: 'AllowStorageHttpsOutbound'
      //   properties: {
      //     priority: 400
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: subnets.storage.addressPrefix
      //     destinationPortRange: '443'
      //   }
      // }
      // denyAllOutboundRule
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
      allowManagementVmInboundRule
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
      allowManagementVmInboundRule
      denyAllInboundRule
      denyAllOutboundRule
    ]
  }
}

resource appServiceManagedHsmNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.appServiceManagedHsm.name}'
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
      allowManagementVmInboundRule
      denyAllInboundRule
      denyAllOutboundRule
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
      allowManagementVmInboundRule
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
      {
        name: 'AllowSqlRedirectOutbound'
        properties: {
          priority: 300
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: subnets.sql.addressPrefix
          destinationPortRange: '11000-11999'
        }
      }
      {
        name: 'DenyVnetOutbound'
        properties: {
          priority: 400
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: addressSpace
          destinationPortRange: '*'
        }
      }
      // Allow traffic destined out of the VNET, no deny all
    ]
  }
}

resource managementVmNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${subnets.managementVm.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowDeveloperSshInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: developerIpAddress
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      denyAllInboundRule
      {
        name: 'AllowAllOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
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
        name: subnets.appServiceManagedHsm.name
        properties: {
          addressPrefix: subnets.appServiceManagedHsm.addressPrefix
          networkSecurityGroup: {
            id: appServiceManagedHsmNsg.id
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
      {
        name: subnets.managementVm.name
        properties: {
          addressPrefix: subnets.managementVm.addressPrefix
          networkSecurityGroup: {
            id: managementVmNsg.id
          }
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
output appServiceEnvironmentNsgResourceId string = appServiceEnvironmentNsg.id
