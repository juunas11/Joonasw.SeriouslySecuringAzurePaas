param location string
param naming object

param vnetName string
param subnetName string
param adminGroupName string
param adminGroupId string

// SQL MI deployment is typically very slow
// Fast provisioning (~30 minutes) is available if:
// - this is the first instance in the subnet
// - 4-8 vCores
// - default maintenance window
// - not zone redundant
resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2023-08-01-preview' = {
  name: naming.sqlManagedInstance
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
  }
  properties: {
    // Ensure fast provisioning with these four settings
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    vCores: 4
    maintenanceConfigurationId: subscriptionResourceId(
      'Microsoft.Maintenance/publicMaintenanceConfigurations',
      'SQL_Default'
    )
    zoneRedundant: false

    storageSizeInGB: 256
    licenseType: 'LicenseIncluded'
    hybridSecondaryUsage: 'Active'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    proxyOverride: 'Proxy'
    // 1.2 is highest supported version
    minimalTlsVersion: '1.2'
    timezoneId: 'UTC'
    requestedBackupStorageRedundancy: 'Local'
    databaseFormat: 'AlwaysUpToDate'
    pricingModel: 'Regular'
    servicePrincipal: {
      type: 'None'
    }
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: adminGroupName
      sid: adminGroupId
      tenantId: tenant().tenantId
      principalType: 'Group'
    }
    publicDataEndpointEnabled: false
  }
}

resource database 'Microsoft.Sql/managedInstances/databases@2023-08-01-preview' = {
  parent: sqlManagedInstance
  name: naming.sqlDatabase
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output sqlManagedInstanceIdentityObjectId string = sqlManagedInstance.identity.principalId
output sqlManagedInstanceFqdn string = sqlManagedInstance.properties.fullyQualifiedDomainName
output sqlDatabaseName string = database.name
