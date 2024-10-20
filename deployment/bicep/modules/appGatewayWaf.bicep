param location string
param naming object

param vnetName string
param appGatewaySubnetName string
param appGatewayPrivateIpAddress string

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01' = {
  name: naming.wafPolicy
  location: location
  properties: {
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 1
      state: 'Enabled'
      mode: 'Detection' // TODO
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: naming.appGateway
  location: location
  zones: []
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    // Note! This requires enabling the "EnableApplicationGatewayNetworkIsolation" preview feature in the subscription currently
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, appGatewaySubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: appGatewayPrivateIpAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, appGatewaySubnetName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'todo.joonasw.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'backendHttpListener'
        properties: {
          firewallPolicy: {
            id: wafPolicy.id
          }
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              naming.appGateway,
              'appGatewayFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', naming.appGateway, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'backendRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              naming.appGateway,
              'backendHttpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              naming.appGateway,
              'appGatewayBackendPool'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              naming.appGateway,
              'httpSettings'
            )
          }
        }
      }
    ]
    // TODO: Test
    enableHttp2: false
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}
