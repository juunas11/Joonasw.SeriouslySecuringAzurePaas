$ErrorActionPreference = 'Stop'

$config = Get-Content -Path (Join-Path $PSScriptRoot config.json) | ConvertFrom-Json

$tenantId = $config.tenantId
$subscriptionId = $config.subscriptionId
$resourceGroup = $config.resourceGroup
$location = $config.location
$domainName = $config.domainName
$sqlAdminGroupName = $config.sqlAdminGroupName
$sqlAdminGroupId = $config.sqlAdminGroupId
$devCenterName = $config.devCenterName
$devCenterProjectName = $config.devCenterProjectName
$azureDevOpsOrganizationUrl = $config.azureDevOpsOrganizationUrl
$azureDevOpsProjectName = $config.azureDevOpsProjectName

# Get PFX as base 64 encoded string
$certificateData = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot cert.pfx)))
# TODO: Get this through secure string (user input)
$certificatePassword = $config.certificatePassword

# Check subscription is available
az account show -s "$subscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    az login -t "$tenantId"
}

# TODO: Check if we already are logged in with correct scope
Connect-MgGraph -TenantId "0d7e0754-812c-4a0f-883f-5f34cf78d354" -Scopes "RoleManagement.ReadWrite.Directory" -NoWelcome

# Ensure resource group exists
$rgExists = az group exists --subscription "$subscriptionId" -g "$resourceGroup"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to check if resource group exists."
}

if ($rgExists -eq "false") {
    Write-Host "Resource group does not exist. Creating resource group..."
    az group create --subscription "$subscriptionId" -g "$resourceGroup" -l "$location"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group."
    }
}

# Deploy Dev Center and project

$devCenterExtension = az extension show -n devcenter --query "name" -o tsv
if ($devCenterExtension -ne "devcenter") {
    Write-Host "Dev Center extension not installed. Installing Dev Center extension..."
    az extension add -n devcenter
}

$devCenterId = az devcenter admin devcenter show -n "$devCenterName" -g "$resourceGroup" --subscription "$subscriptionId" --query "id" -o tsv

if ($null -eq $devCenterId) {
    Write-Host "Dev Center does not exist. Creating Dev Center..."
    $devCenterId = az devcenter admin devcenter create -n "$devCenterName" -g "$resourceGroup" --subscription "$subscriptionId" --query "id" -o tsv
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create Dev Center."
    }
}

Write-Host "Dev Center ID: $devCenterId"

$devCenterProjectId = az devcenter admin project show -n "$devCenterProjectName" -g "$resourceGroup" --subscription "$subscriptionId" --query "id" -o tsv
if ($null -eq $devCenterProjectId) {
    Write-Host "Dev Center project does not exist. Creating Dev Center project..."
    $devCenterProjectId = az devcenter admin project create -n "$devCenterProjectName" -g "$resourceGroup" --subscription "$subscriptionId" --dev-center-id "$devCenterId" --query "id" -o tsv
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create Dev Center project."
    }
}

Write-Host "Dev Center project ID: $devCenterProjectId"

# Get DevOpsInfrastructure service principal ID

$devOpsInfrastructureSpId = az ad sp list --filter "displayName eq 'DevOpsInfrastructure'" --query "[].id" -o tsv
if ($LASTEXITCODE -ne 0) {
    throw "Failed to get DevOpsInfrastructure service principal ID."
}

if ($null -eq $devOpsInfrastructureSpId) {
    throw "DevOpsInfrastructure service principal not found."
}

# Deploy Bicep template

Push-Location -Path (Join-Path $PSScriptRoot bicep)

## Get SQL NSG and Route Table resource IDs
## SQL MI sets up its own things in these after creation and we don't want to touch them after they are created
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
    -p sqlNsgResourceId=$sqlNsgResourceId `
    -p sqlRouteTableResourceId=$sqlRouteTableResourceId `
    -p azureDevOpsOrganizationUrl=$azureDevOpsOrganizationUrl `
    -p azureDevOpsProjectName=$azureDevOpsProjectName `
    -p devCenterProjectResourceId=$devCenterProjectId `
    -p devOpsInfrastructureSpId=$devOpsInfrastructureSpId | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "Failed to deploy main.bicep."
}

$mainBicepOutputs = $mainBicepResult.properties.outputs

$firewallPublicIpAddress = $mainBicepOutputs.firewallPublicIpAddress.value
$sqlManagedInstanceIdentityObjectId = $mainBicepOutputs.sqlManagedInstanceIdentityObjectId.value

Pop-Location

## Assign Directory Readers role to SQL MI managed identity

$directoryReadersRoleId = (Get-MgDirectoryRole -Filter "displayName eq 'Directory Readers'").Id
if ($null -eq $directoryReadersRoleId) {
    throw "Directory Readers role not found."
}

$directoryReadersRoleMember = Get-MgDirectoryRoleMember -DirectoryRoleId $directoryReadersRoleId | Where-Object { $_.Id -eq $sqlManagedInstanceIdentityObjectId }
if ($null -ne $directoryReadersRoleMember) {
    Write-Host "SQL MI managed identity is already a member of Directory Readers role."
}
else {
    Write-Host "Adding SQL MI managed identity to Directory Readers role..."
    $addRoleMemberBody = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$sqlManagedInstanceIdentityObjectId"
    }

    New-MgDirectoryRoleMemberByRef -DirectoryRoleId $directoryReadersRoleId -BodyParameter $addRoleMemberBody
}

Write-Host "Deployment complete."
Write-Host "You need to now set up a DNS A record: $domainName -> $firewallPublicIpAddress"
