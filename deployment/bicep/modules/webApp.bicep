param location string
param naming object

param appServiceEnvironmentResourceId string
param appServicePlanResourceId string
// param keyVaultResourceId string
param storageAccountResourceId string
// param appVnetName string
param subnets object
// param appServiceDnsZoneResourceId string
// param dataProtectionKeyUri string
param appInsightsConnectionString string
param dataProtectionManagedHsmName string
param dataProtectionKeyName string
param appServiceEnvironmentDnsZoneResourceId string
param appServiceEnvironmentIpAddress string

// var keyVaultName = last(split(keyVaultResourceId, '/'))
var storageAccountName = last(split(storageAccountResourceId, '/'))

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   name: keyVaultName
// }

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: naming.webApp
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanResourceId
    hostingEnvironmentProfile: {
      id: appServiceEnvironmentResourceId
    }
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    vnetRouteAllEnabled: true
    siteConfig: {
      appSettings: [
        {
          // TODO: Set SQL server and DB from params
          name: 'ConnectionStrings__Sql'
          value: 'Server=tcp:sql-x43ywukzvc6uu.46cc585a7110.${environment().suffixes.sqlServerHostname},1433;Database=sqldbx43ywukzvc6uu;Encrypt=True;TrustServerCertificate=False;Authentication="Active Directory Managed Identity"'
        }
        {
          name: 'DataProtection__StorageBlobUri'
          value: '${storageAccount.properties.primaryEndpoints.blob}${naming.storageWebAppDataProtectionContainer}/keys.xml'
        }
        {
          // Example: https://kv-app-dp-zktdtyvkxu3lk.managedhsm.azure.net/keys/kv-app-dp-key
          name: 'DataProtection__KeyVaultKeyUri'
          value: 'https://${dataProtectionManagedHsmName}.managedhsm.azure.net/keys/${dataProtectionKeyName}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      // Require TLS 1.3 for incoming connections
      // (TLS 1.2 would be enough for most cases)
      // (Do check your minimum cipher suite such that all of them support authenticated encryption and forward secrecy)
      minTlsVersion: '1.3'
      remoteDebuggingEnabled: false
      scmMinTlsVersion: '1.3'
      ipSecurityRestrictionsDefaultAction: 'Deny'
      ipSecurityRestrictions: [
        {
          priority: 100
          name: 'AllowApplicationGateway'
          ipAddress: subnets.appGateway.addressPrefix
          action: 'Allow'
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictions: [
        {
          priority: 100
          name: 'AllowBuildAgent'
          ipAddress: subnets.buildAgent.addressPrefix
          action: 'Allow'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// resource webAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
//   name: naming.webAppPrivateEndpoint
//   location: location
//   properties: {
//     subnet: {
//       id: resourceId('Microsoft.Network/virtualNetworks/subnets', appVnetName, subnets.webAppInbound.name)
//     }
//     privateLinkServiceConnections: [
//       {
//         name: '${naming.webApp}-privateLinkServiceConnection'
//         properties: {
//           privateLinkServiceId: webApp.id
//           groupIds: [
//             'sites'
//           ]
//         }
//       }
//     ]
//   }
// }

// resource webAppPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
//   parent: webAppPrivateEndpoint
//   name: 'PrivateEndpointPrivateDnsZoneGroup'
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'privatelink-azurewebsites-net'
//         properties: {
//           privateDnsZoneId: appServiceDnsZoneResourceId
//         }
//       }
//     ]
//   }
// }

// resource vnetIntegration 'Microsoft.Web/sites/networkConfig@2023-12-01' = {
//   parent: webApp
//   name: 'virtualNetwork'
//   properties: {
//     subnetResourceId: resourceId(
//       'Microsoft.Network/virtualNetworks/subnets',
//       appVnetName,
//       subnets.app.webAppOutbound.name
//     )
//   }
// }

module webAppDns './webAppDns.bicep' = {
  name: '${deployment().name}-webAppDns'
  params: {
    webAppFqdn: webApp.properties.defaultHostName
    appServiceEnvironmentDnsZoneResourceId: appServiceEnvironmentDnsZoneResourceId
    appServiceEnvironmentIpAddress: appServiceEnvironmentIpAddress
  }
}

// TODO: Check this role works with managed HSM since the data actions are Microsoft.KeyVault/vaults/keys/wrap etc

// resource webAppKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(naming.webApp, keyVault.id, 'Key Vault Crypto Service Encryption User')
//   scope: keyVault
//   properties: {
//     principalId: webApp.identity.principalId
//     principalType: 'ServicePrincipal'
//     // Key Vault Crypto Service Encryption User
//     roleDefinitionId: subscriptionResourceId(
//       'Microsoft.Authorization/roleDefinitions',
//       'e147488a-f6f5-4113-8e2d-b22465e65bf6'
//     )
//   }
// }

// TODO: Change role assignment to container level

resource webAppStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(naming.webApp, storageAccount.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    // Storage Blob Data Contributor
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
  }
}

output webAppFqdn string = webApp.properties.defaultHostName
output webAppName string = webApp.name
