param location string
param naming object

param appServiceEnvironmentResourceId string

// Deployment takes 30 minutes
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: naming.appServicePlan
  location: location
  sku: {
    name: 'I1V2'
    tier: 'Isolated'
    capacity: 1
  }
  properties: {
    hostingEnvironmentProfile: {
      id: appServiceEnvironmentResourceId
    }
  }
}

output appServicePlanResourceId string = appServicePlan.id
