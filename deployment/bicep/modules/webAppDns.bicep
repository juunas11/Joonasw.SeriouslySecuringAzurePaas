param appServiceEnvironmentDnsZoneResourceId string
param appServiceEnvironmentIpAddress string
param webAppFqdn string

var appServiceEnvironmentDnsZoneName = last(split(appServiceEnvironmentDnsZoneResourceId, '/'))
var webAppDomainForDnsRecord = replace(webAppFqdn, '.appserviceenvironment.net', '')
var scmDomainForDnsRecord = replace(webAppDomainForDnsRecord, '.', '.scm.')

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: appServiceEnvironmentDnsZoneName
}

resource appRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
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

resource scmRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: dnsZone
  name: scmDomainForDnsRecord
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appServiceEnvironmentIpAddress
      }
    ]
  }
}
