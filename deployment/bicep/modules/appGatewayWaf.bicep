param location string
param naming object

param vnetName string
param appGatewaySubnetName string
param appGatewayPrivateIpAddress string
param webAppFqdn string

@secure()
param certificateData string
@secure()
param certificatePassword string

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
      // We don't have file uploads
      fileUploadLimitInMb: 0
      state: 'Enabled'
      mode: 'Prevention'
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
              fqdn: webAppFqdn
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
          // Seconds
          requestTimeout: 30
        }
      }
      {
        name: 'httpsSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          // Seconds
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'frontendHttpListener'
        properties: {
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
        }
      }
      {
        name: 'backendHttpsListener'
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
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', naming.appGateway, 'port_443')
          }
          protocol: 'Https'
          requireServerNameIndication: false
          sslCertificate: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/sslCertificates',
              naming.appGateway,
              'appGatewaySslCert'
            )
          }
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
              'backendHttpsListener'
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
              'httpsSettings'
            )
          }
        }
      }
      {
        name: 'httpToHttpsRedirectRule'
        properties: {
          ruleType: 'Basic'
          priority: 20
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              naming.appGateway,
              'frontendHttpListener'
            )
          }
          redirectConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/redirectConfigurations',
              naming.appGateway,
              'httpToHttpsRedirect'
            )
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'httpToHttpsRedirect'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              naming.appGateway,
              'backendHttpsListener'
            )
          }
          includePath: true
          includeQueryString: true
        }
      }
    ]
    // TODO: Test
    enableHttp2: false
    firewallPolicy: {
      id: wafPolicy.id
    }
    sslCertificates: [
      {
        name: 'appGatewaySslCert'
        properties: {
          data: certificateData
          password: certificatePassword
        }
      }
    ]
    sslPolicy: {
      // We _could_ require TLS 1.3 and only select cipher suites here
      // This built-in is quite strict already though (TLS 1.2 + 6 cipher suites)
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101S'
    }
  }
}
