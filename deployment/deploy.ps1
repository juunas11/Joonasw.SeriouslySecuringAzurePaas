$ErrorActionPreference = 'Stop'

$config = Get-Content -Path (Join-Path $PSScriptRoot config.json) -Raw | ConvertFrom-Json

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
$initialManagedHsmAdminObjectId = $config.initialManagedHsmAdminObjectId
$developerIpAddress = $config.developerIpAddress
$managementVmAdminUsername = $config.managementVmAdminUsername
$managementVmAdminSshPublicKeyFilePath = $config.managementVmAdminSshPublicKeyFilePath
$entraIdAuthTenantDomain = $config.entraIdAuthTenantDomain
$entraIdClientId = $config.entraIdClientId
$limitedDeveloperUserObjectId = $config.limitedDeveloperUserObjectId
$webAppDataProtectionKeyName = "DataProtectionKeyEncryptionKey"

# Get PFX as base 64 encoded string
$certificateData = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot cert.pfx)))
# TODO: Get this through secure string (user input)
$certificatePassword = $config.certificatePassword

$managementVmAdminSshPublicKey = (Get-Content -Path $managementVmAdminSshPublicKeyFilePath -Raw).Trim()

# Check subscription is available
az account show -s "$subscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    az login -t "$tenantId"
}

$graphContext = Get-MgContext
if ($graphContext.TenantId -ne $tenantId -or $graphContext.Scopes -notcontains "RoleManagement.ReadWrite.Directory") {
    Connect-MgGraph -TenantId "$tenantId" -Scopes "RoleManagement.ReadWrite.Directory" -NoWelcome
}

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
    -p devOpsInfrastructureSpId=$devOpsInfrastructureSpId `
    -p webAppDataProtectionKeyName=$webAppDataProtectionKeyName `
    -p initialManagedHsmAdminObjectId=$initialManagedHsmAdminObjectId `
    -p developerIpAddress=$developerIpAddress `
    -p managementVmAdminUsername=$managementVmAdminUsername `
    -p managementVmAdminSshPublicKey=$managementVmAdminSshPublicKey `
    -p appDomainName=$domainName `
    -p entraIdAuthTenantDomain=$entraIdAuthTenantDomain `
    -p entraIdClientId=$entraIdClientId `
    -p limitedDeveloperUserObjectId=$limitedDeveloperUserObjectId | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "Failed to deploy main.bicep."
}

$mainBicepOutputs = $mainBicepResult.properties.outputs

$firewallPublicIpAddress = $mainBicepOutputs.firewallPublicIpAddress.value
$sqlManagedInstanceIdentityObjectId = $mainBicepOutputs.sqlManagedInstanceIdentityObjectId.value
$managedDevopsPoolName = $mainBicepOutputs.managedDevopsPoolName.value
$managedDevopsPoolIdentityObjectId = $mainBicepOutputs.managedDevopsPoolIdentityObjectId.value
$managedDevopsPoolIdentityName = $mainBicepOutputs.managedDevopsPoolIdentityName.value
$webAppName = $mainBicepOutputs.webAppName.value
$webAppIdentityObjectId = $mainBicepOutputs.webAppIdentityObjectId.value
$webAppDataProtectionManagedHsmName = $mainBicepOutputs.webAppDataProtectionManagedHsmName.value
$managementVmPublicIpAddress = $mainBicepOutputs.managementVmPublicIpAddress.value
$sqlServerFqdn = $mainBicepOutputs.sqlServerFqdn.value
$sqlDatabaseName = $mainBicepOutputs.sqlDatabaseName.value

Pop-Location

# Update build pipeline values

$buildAndReleasePipeline = Get-Content -Path (Join-Path $PSScriptRoot pipelines build-and-release.yaml) -Raw

$buildAndReleasePipeline = $buildAndReleasePipeline -replace '(devops-pool-[\da-z]*)', $managedDevopsPoolName

Set-Content -Path (Join-Path $PSScriptRoot pipelines build-and-release.yaml) -Value $buildAndReleasePipeline -NoNewline

Write-Host "Build pipeline agent pool updated to $managedDevopsPoolName."

$variablesFileContent = Get-Content -Path (Join-Path $PSScriptRoot pipelines variables.template.yaml) -Raw
$variablesFileContent = $variablesFileContent -replace '\$\(SqlServer\)', $sqlServerFqdn
$variablesFileContent = $variablesFileContent -replace '\$\(SqlDatabase\)', $sqlDatabaseName
$variablesFileContent = $variablesFileContent -replace '\$\(WebApp\)', $webAppName
$variablesFileContent = $variablesFileContent -replace '\$\(ResourceGroup\)', $resourceGroup
$variablesFileContent = $variablesFileContent -replace '\$\(ManagedIdentityObjectId\)', $managedDevopsPoolIdentityObjectId

Set-Content -Path (Join-Path $PSScriptRoot pipelines variables.yaml) -Value $variablesFileContent -NoNewline

Write-Host "Build pipeline variables file updated."

# Update management VM script variables

$managedHsmScript = Get-Content -Path (Join-Path $PSScriptRoot setup-managedhsm.sh) -Raw
$managedHsmScript = $managedHsmScript -replace '(SUBSCRIPTION_ID=.*)', "SUBSCRIPTION_ID=$subscriptionId"
$managedHsmScript = $managedHsmScript -replace '(HSM_NAME=.*)', "HSM_NAME=$webAppDataProtectionManagedHsmName"
$managedHsmScript = $managedHsmScript -replace '(ADMIN_OBJECT_ID=.*)', "ADMIN_OBJECT_ID=$initialManagedHsmAdminObjectId"
$managedHsmScript = $managedHsmScript -replace '(WEB_APP_OBJECT_ID=.*)', "WEB_APP_OBJECT_ID=$webAppIdentityObjectId"
$managedHsmScript = $managedHsmScript -replace '(DATA_PROTECTION_KEY_NAME=.*)', "DATA_PROTECTION_KEY_NAME=$webAppDataProtectionKeyName"
$managedHsmScript = $managedHsmScript -replace '(TENANT_ID=.*)', "TENANT_ID=$tenantId"

Set-Content -Path (Join-Path $PSScriptRoot setup-managedhsm.sh) -Value $managedHsmScript -NoNewline

$sqlSetupScript = Get-Content -Path (Join-Path $PSScriptRoot setup-sql.sh) -Raw
$sqlSetupScript = $sqlSetupScript -replace '(DEVOPS_POOL_IDENTITY_NAME=.*)', "DEVOPS_POOL_IDENTITY_NAME=$managedDevopsPoolIdentityName"
$sqlSetupScript = $sqlSetupScript -replace '(WEB_APP_NAME=.*)', "WEB_APP_NAME=$webAppName"
$sqlSetupScript = $sqlSetupScript -replace '(SQL_SERVER_FQDN=.*)', "SQL_SERVER_FQDN=$sqlServerFqdn"
$sqlSetupScript = $sqlSetupScript -replace '(SQL_DATABASE_NAME=.*)', "SQL_DATABASE_NAME=$sqlDatabaseName"

Set-Content -Path (Join-Path $PSScriptRoot setup-sql.sh) -Value $sqlSetupScript -NoNewline

Write-Host "Management VM setup scripts updated."

# Assign Directory Readers role to SQL MI managed identity

Write-Host "Assigning Directory Readers role to SQL MI managed identity..."

$directoryReadersRoleId = (Get-MgDirectoryRole -Filter "displayName eq 'Directory Readers'").Id
if ($null -eq $directoryReadersRoleId) {
    throw "Directory Readers role not found."
}

$directoryReadersRoleMember = Get-MgDirectoryRoleMemberAsServicePrincipal -DirectoryObjectId $sqlManagedInstanceIdentityObjectId -DirectoryRoleId $directoryReadersRoleId
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
Write-Host "Connect with SSH to management VM to setup HSM and set SQL permissions. Username: $managementVmAdminUsername, IP: $managementVmPublicIpAddress"