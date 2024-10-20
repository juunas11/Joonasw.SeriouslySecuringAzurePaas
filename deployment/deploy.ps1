# TODO: Fix path so it uses the PS script path
$config = Get-Content -Path .\config.json | ConvertFrom-Json

$tenantId = $config.tenantId
$subscriptionId = $config.subscriptionId
$resourceGroup = $config.resourceGroup

# Deploy Bicep template

# az login --tenant $tenantId
# az account set --subscription $subscriptionId

$deploymentName = "deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
    --resource-group $resourceGroup `
    --template-file .\bicep\main.bicep `
    --name $deploymentName