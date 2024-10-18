param location string
param naming object

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: naming.firewall
  location: location
  properties: {
    hubIPAddresses: {
      privateIPAddress: ''
      publicIPs: {
        addresses: [
          {
            address: ''
          }
        ]
      }
    }
    sku: {
      name: 'AZFW_Hub'
      tier: 'Basic'
    }
    // threatIntelMode: 'Alert'
  }
}
