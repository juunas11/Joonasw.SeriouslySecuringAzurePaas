param location string
param naming object

param vnetName string
param subnetName string
param adminUsername string
@secure()
param adminPassword string

resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: naming.buildAgentVmScaleSet
  location: location
  zones: []
  sku: {
    name: 'Standard_D2as_v5'
    capacity: 0
  }
  // TODO: CMK for VMSS encryption?
  properties: {
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'fromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          diskSizeGB: 128
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-datacenter-azure-edition'
          version: 'latest'
        }
      }
      networkProfile: {
        networkApiVersion: '2020-11-01'
        networkInterfaceConfigurations: [
          {
            name: naming.buildAgentVmNic
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              ipConfigurations: [
                {
                  name: '${naming.buildAgentVmNic}-defaultIpConfiguration'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                    primary: true
                  }
                }
              ]
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: naming.buildAgentVmNamePrefix
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
          enableAutomaticUpdates: true
          patchSettings: {
            enableHotpatching: false
            patchMode: 'AutomaticByOS'
          }
        }
      }
      securityProfile: {
        securityType: 'TrustedLaunch'
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
      }
    }
    orchestrationMode: 'Flexible'
    platformFaultDomainCount: 1
    scaleInPolicy: {
      forceDeletion: false
      rules: [
        'Default'
      ]
    }
    upgradePolicy: {
      mode: 'Automatic'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
  }
}
