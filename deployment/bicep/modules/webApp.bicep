param location string
param naming object

param appServiceEnvironmentResourceId string
param appServicePlanResourceId string
// param keyVaultResourceId string
param storageAccountResourceId string
param storageWebAppDataProtectionContainerName string
// param appVnetName string
param subnets object
// param appServiceDnsZoneResourceId string
// param dataProtectionKeyUri string
param appInsightsConnectionString string
param dataProtectionManagedHsmName string
param dataProtectionKeyName string
param appServiceEnvironmentDnsZoneResourceId string
param appServiceEnvironmentIpAddress string
param sqlServerFqdn string
param sqlDatabaseName string

// var keyVaultName = last(split(keyVaultResourceId, '/'))
var storageAccountName = last(split(storageAccountResourceId, '/'))

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   name: keyVaultName
// }

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' existing = {
  parent: storageAccountBlobService
  name: storageWebAppDataProtectionContainerName
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
          name: 'ConnectionStrings__Sql'
          value: 'Server=${sqlServerFqdn};Database=${sqlDatabaseName};Encrypt=True;Authentication=Active Directory Managed Identity'
        }
        {
          name: 'DataProtection__StorageBlobUri'
          value: '${storageAccount.properties.primaryEndpoints.blob}${naming.storageWebAppDataProtectionContainer}/keys.xml'
        }
        {
          name: 'DataProtection__KeyVaultKeyUri'
          value: 'https://${dataProtectionManagedHsmName}.managedhsm.azure.net/keys/${dataProtectionKeyName}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'EntraId__Domain'
          value: ''
        }
        {
          name: 'EntraId__TenantId'
          value: ''
        }
        {
          name: 'EntraId__ClientId'
          value: ''
        }
        // TODO: Entra settings (how do we configure "organizations" for the domain)
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
        {
          priority: 200
          name: 'AllowManagementVm'
          ipAddress: subnets.managementVm.addressPrefix
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
        {
          priority: 200
          name: 'AllowManagementVm'
          ipAddress: subnets.managementVm.addressPrefix
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

module webAppDns './webAppDns.bicep' = {
  name: '${deployment().name}-webAppDns'
  params: {
    webAppFqdn: webApp.properties.defaultHostName
    appServiceEnvironmentDnsZoneResourceId: appServiceEnvironmentDnsZoneResourceId
    appServiceEnvironmentIpAddress: appServiceEnvironmentIpAddress
  }
}

resource webAppStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    naming.webApp,
    storageAccount.id,
    storageWebAppDataProtectionContainerName,
    'Storage Blob Data Contributor'
  )
  scope: storageAccountContainer
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
