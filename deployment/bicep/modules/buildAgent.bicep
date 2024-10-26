param location string
param naming object

param vnetName string
param subnetName string
param azureDevOpsOrganizationUrl string
param azureDevOpsProjectName string
param devCenterProjectResourceId string

resource managedDevopsPool 'Microsoft.DevOpsInfrastructure/pools@2024-04-04-preview' = {
  location: location
  name: naming.buildAgentPool
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    organizationProfile: {
      kind: 'AzureDevOps'
      organizations: [
        {
          url: azureDevOpsOrganizationUrl
          parallelism: 1
          projects: [
            azureDevOpsProjectName
          ]
        }
      ]
      permissionProfile: {
        kind: 'CreatorOnly'
      }
    }
    agentProfile: {
      kind: 'Stateless'
    }
    devCenterProjectResourceId: devCenterProjectResourceId
    maximumConcurrency: 1
    fabricProfile: {
      kind: 'Vmss'
      sku: {
        name: 'Standard_D2as_v5'
      }
      images: [
        {
          wellKnownImageName: 'windows-2022'
          buffer: '*'
        }
      ]
      networkProfile: {
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
      }
    }
  }
}
