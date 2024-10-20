param location string
param naming object

param vnetName string
param subnetName string

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
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    storageSizeInGB: 256
    vCores: 4
    licenseType: 'LicenseIncluded'
    hybridSecondaryUsage: 'Active'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    proxyOverride: 'Proxy'
    minimalTlsVersion: '1.2'
    timezoneId: 'UTC'
    requestedBackupStorageRedundancy: 'Local'
    zoneRedundant: false
    databaseFormat: 'AlwaysUpToDate'
    pricingModel: 'Regular'
    servicePrincipal: {
      type: 'None'
    }
    maintenanceConfigurationId: subscriptionResourceId(
      'Microsoft.Maintenance/publicMaintenanceConfigurations',
      'SQL_Default'
    )
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: ''
      sid: ''
      tenantId: tenant().tenantId
      principalType: 'Group'
    }
  }
}
