param location string
param naming object

param appServiceEnvironmentResourceId string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: naming.appServicePlan
  location: location
  sku: {
    name: 'I1v2'
    tier: 'Isolated'
    capacity: 1
  }
  properties: {
    hostingEnvironmentProfile: {
      id: appServiceEnvironmentResourceId
    }
  }
}
