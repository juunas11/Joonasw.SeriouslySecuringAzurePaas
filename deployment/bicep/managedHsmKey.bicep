param managedHsmName string
param keyName string

@allowed([
  'RSA'
  'RSA-HSM'
  'EC'
  'EC-HSM'
])
param kty string
param keyOps array
param keySize int = 0
param curveName string = ''

resource managedHsm 'Microsoft.KeyVault/managedHSMs@2023-07-01' existing = {
  name: managedHsmName
}

resource key 'Microsoft.KeyVault/managedHSMs/keys@2023-07-01' = {
  parent: managedHsm
  name: keyName
  properties: {
    kty: kty
    keySize: keySize == 0 ? null : keySize
    curveName: curveName == '' ? null : curveName
    // Could define a rotation policy here
    keyOps: keyOps
    attributes: {
      enabled: true
      exportable: false
    }
  }
}

output keyUri string = key.properties.keyUriWithVersion
