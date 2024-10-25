param location string
param naming object

param appServiceEnvironmentResourceId string
param appServicePlanResourceId string
param keyVaultResourceId string
param storageAccountResourceId string
param subnets object

var keyVaultName = last(split(keyVaultResourceId, '/'))
var storageAccountName = last(split(storageAccountResourceId, '/'))

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

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
    publicNetworkAccess: 'Disabled'
    siteConfig: {
      appSettings: [
        {
          name: 'KeyVault__Uri'
          value: keyVault.properties.vaultUri
        }
        {
          name: 'StorageAccount__BlobEndpointUri'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'StorageAccount__ContainerName'
          value: naming.storageWebAppAuthenticationContainer
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
      // TODO: Check these produce the settings we want
      ipSecurityRestrictions: [
        {
          name: 'AllowTrafficFromAppGateway'
          ipAddress: subnets.appGateway.addressPrefix
          action: 'Allow'
          priority: 100
        }
      ]
      ipSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictions: [
        {
          name: 'AllowTrafficFromBuildAgent'
          ipAddress: subnets.buildAgent.addressPrefix
          action: 'Allow'
          priority: 100
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource webAppKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(naming.webApp, keyVault.id, 'Key Vault Crypto Service Encryption User')
  scope: keyVault
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    // Key Vault Crypto Service Encryption User
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'e147488a-f6f5-4113-8e2d-b22465e65bf6'
    )
  }
}

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
