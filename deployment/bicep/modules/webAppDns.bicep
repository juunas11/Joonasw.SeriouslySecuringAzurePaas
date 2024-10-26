param appServiceEnvironmentDnsZoneResourceId string
param appServiceEnvironmentIpAddress string
param webAppFqdn string

var appServiceEnvironmentDnsZoneName = last(split(appServiceEnvironmentDnsZoneResourceId, '/'))
var webAppDomainForDnsRecord = replace(webAppFqdn, '.appserviceenvironment.net', '')

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: appServiceEnvironmentDnsZoneName
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: dnsZone
  name: webAppDomainForDnsRecord
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appServiceEnvironmentIpAddress
      }
    ]
  }
}
