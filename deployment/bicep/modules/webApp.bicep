param location string
param naming object

param appServiceEnvironmentResourceId string
param appServicePlanResourceId string
param storageAccountResourceId string
param storageWebAppDataProtectionContainerName string
param subnets object
param appInsightsConnectionString string
param dataProtectionManagedHsmName string
param dataProtectionKeyName string
param appServiceEnvironmentDnsZoneResourceId string
param appServiceEnvironmentIpAddress string
param sqlServerFqdn string
param sqlDatabaseName string
param entraIdAuthTenantDomain string
param entraIdClientId string

var storageAccountName = last(split(storageAccountResourceId, '/'))

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
          name: 'DataProtection__ManagedHsmKeyUri'
          value: 'https://${dataProtectionManagedHsmName}.managedhsm.azure.net/keys/${dataProtectionKeyName}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'EntraId__Domain'
          value: entraIdAuthTenantDomain
        }
        {
          name: 'EntraId__TenantId'
          value: 'organizations'
        }
        {
          name: 'EntraId__ClientId'
          value: entraIdClientId
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'true'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      // Require TLS 1.3 for incoming connections
      // (TLS 1.2 would be enough for most cases)
      // (Do check your minimum cipher suite such that all of them support authenticated encryption and forward secrecy)
      // Note this only applies for the connection between the App Service and App Gateway
      minTlsVersion: '1.3'
      // Also require the highest cipher suite
      // TODO: See if App Gateway supports this cipher suite
      minTlsCipherSuite: 'TLS_AES_256_GCM_SHA384'
      remoteDebuggingEnabled: false
      // This applies to connections between the App Service and the build agent
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
output webAppIdentityObjectId string = webApp.identity.principalId
