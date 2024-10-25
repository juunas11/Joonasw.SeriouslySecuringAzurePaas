$ErrorActionPreference = 'Stop'

$config = Get-Content -Path (Join-Path $PSScriptRoot config.json) | ConvertFrom-Json

$tenantId = $config.tenantId
$subscriptionId = $config.subscriptionId
$resourceGroup = $config.resourceGroup
$domainName = $config.domainName
$sqlAdminGroupName = $config.sqlAdminGroupName
$sqlAdminGroupId = $config.sqlAdminGroupId
$buildAgentAdminUsername = $config.buildAgentAdminUsername
# TODO: Get this through secure string (user input)
$buildAgentAdminPassword = $config.buildAgentAdminPassword

# Get PFX as base 64 encoded string
$certificateData = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot cert.pfx)))
# TODO: Get this through secure string (user input)
$certificatePassword = $config.certificatePassword

# Check subscription is available
az account show -s "$subscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    az login -t "$tenantId"
}

# Deploy Bicep template

Push-Location -Path (Join-Path $PSScriptRoot bicep)

## Get SQL NSG and Route Table resource IDs
$sqlNsg = az network nsg list -g "$resourceGroup" --subscription "$subscriptionId" --query "[].{id:id,name:name}" | ConvertFrom-Json | Where-Object { $_.name -eq 'nsg-app-sql' }
$sqlRouteTable = az network route-table list -g "$resourceGroup" --subscription "$subscriptionId" --query "[].{id:id,name:name}" | ConvertFrom-Json | Where-Object { $_.name.StartsWith('rt-app-sql') }

$deploymentNamePrefix = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

$sqlNsgResourceId = $sqlNsg.id
$sqlRouteTableResourceId = $sqlRouteTable.id

$mainBicepResult = az deployment group create `
    --subscription "$subscriptionId" `
    --resource-group "$resourceGroup" `
    --template-file "main.bicep" `
    --name "$($deploymentNamePrefix)-main" `
    -p appGatewayCertificateData=$certificateData `
    -p appGatewayCertificatePassword=$certificatePassword `
    -p sqlAdminGroupName=$sqlAdminGroupName `
    -p sqlAdminGroupId=$sqlAdminGroupId `
    -p buildAgentAdminUsername=$buildAgentAdminUsername `
    -p buildAgentAdminPassword=$buildAgentAdminPassword `
    -p sqlNsgResourceId=$sqlNsgResourceId `
    -p sqlRouteTableResourceId=$sqlRouteTableResourceId | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "Failed to deploy main.bicep."
}

$mainBicepOutputs = $mainBicepResult.properties.outputs

Pop-Location

Write-Host "Deployment complete."
Write-Host "You need to now set up a DNS A record: $domainName -> $($mainBicepOutputs.firewallPublicIpAddress.value)"

# az extension add --name azure-devops
# az devops configure --defaults organization=https://dev.azure.com/contoso project=ContosoWebApp
# Let's see if we setup everything in DevOps here or just write up the steps