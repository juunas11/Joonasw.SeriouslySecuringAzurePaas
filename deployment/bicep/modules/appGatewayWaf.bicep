param location string
param naming object

param vnetName string
param appGatewaySubnetName string
param appGatewayPrivateIpAddress string
param webAppFqdn string
param appDomainName string
param logAnalyticsWorkspaceId string

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
          ruleSetVersion: '3.2'
          ruleGroupOverrides: [
            {
              // TODO: Test this
              ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
              rules: [
                {
                  // Host header is a numeric IP address
                  ruleId: '920350'
                  // Default action is Anomaly score
                  // I would like to block them as the app doesn't work correctly
                  action: 'Block'
                  state: 'Enabled'
                }
              ]
            }
          ]
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
      exclusions: [
        // Exclude the two cookies' values from SQL comment checks (they can contain double dashes, causing random blocks)
        {
          matchVariable: 'RequestCookieValues'
          selector: '.AspNetCore.Cookies'
          selectorMatchOperator: 'StartsWith'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      // SQL Comment Sequence Detected
                      ruleId: '942440'
                    }
                  ]
                }
              ]
            }
          ]
        }

        {
          matchVariable: 'RequestCookieValues'
          selector: '.AspNetCore.Antiforgery'
          selectorMatchOperator: 'StartsWith'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      // SQL Comment Sequence Detected
                      ruleId: '942440'
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      requestBodyEnforcement: true
      fileUploadLimitInMb: 1
      fileUploadEnforcement: true
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
          rewriteRuleSet: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/rewriteRuleSets',
              naming.appGateway,
              'RewriteAuthLocationRedirectUri'
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
    rewriteRuleSets: [
      {
        // The App Service redirects the user to login with Entra ID
        // and the redirect_uri parameter contains the App Service FQDN.
        // This rule rewrites the redirect_uri to use the domain that
        // is mapped to the Firewall's public IP.
        name: 'RewriteAuthLocationRedirectUri'
        properties: {
          rewriteRules: [
            {
              name: 'RewriteAuthLocationRedirectUri'
              ruleSequence: 100
              conditions: [
                {
                  variable: 'http_resp_Location'
                  pattern: '(.*)${webAppFqdn}(.*)'
                  ignoreCase: true
                }
              ]
              actionSet: {
                responseHeaderConfigurations: [
                  {
                    headerName: 'Location'
                    headerValue: '{http_resp_Location_1}${appDomainName}{http_resp_Location_2}'
                  }
                ]
              }
            }
          ]
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
      // Require TLS 1.3
      // (Using a predefined policy that requires 1.2+ would be enough for most cases)
      // (Do check the ciphers support authenticated encryption and forward secrecy though)
      policyType: 'CustomV2'
      minProtocolVersion: 'TLSv1_3'
      cipherSuites: [
        'TLS_AES_128_GCM_SHA256'
        'TLS_AES_256_GCM_SHA384'
      ]
    }
  }
}

resource wafDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'waf-logs-to-loganalytics'
  scope: appGateway
  properties: {
    logs: [
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: []
    workspaceId: logAnalyticsWorkspaceId
  }
}
