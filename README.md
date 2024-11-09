# Joonasw.SeriouslySecuringAzurePaas

Demo for Cloudbrew 2024

## Azure components

- Virtual networks (hub + spoke)
- Azure private DNS zones
- Azure Firewall
- Azure Monitor Private Link Scope
- Application Gateway WAF
- App Service Environmnet
- Azure SQL Managed Instance
- Azure Key Vault Managed HSM
- Storage account
- Managed DevOps Pool
- Dev Center
- Ubuntu Linux VM
- Application Insights
- Log Analytics
- Custom RBAC role

## Prerequisites for deployment

- Azure CLI
- PowerShell
- Microsoft.Graph module for PowerShell
- HTTPS certificate (script expects it to be at "deployment/cert.pfx")
- The "EnableApplicationGatewayNetworkIsolation" preview flag must be enabled on the subscription
- Enough credits in your Azure subscription (this will use hundreds of EUR/USD quickly)
- Enough rights in the Entra ID tenant to assign the SQL MI principal to Directory Readers role
  - If you don't have this, comment out the bit in deploy.ps1 that does this assignment. You'll need someone else to assign the role to the system-assigned Managed Identity of the SQL MI.
- Owner rights in the resource group
- Service connection in Azure DevOps (described next)
- App registration in Entra ID for the app

## Create Azure DevOps service connection

1. Go to Project settings
1. Service connections
1. Create service connection
1. Type: Azure Resource Manager
1. Authentication method: Workload Identity federation (automatic)
1. Scope level: Subscription
1. Select your subscription
1. Service connection name: Enter something
1. Save

Once the service connection has been created, open it and click "Manage App registration".
You will find the app's name.

Now open the subscription or resource group you intend to deploy to, and go to "Access control (IAM)".

TODO: Test that this role works

Add the "Website Contributor" role to the created app.
The only thing the publish pipeline does is release new versions to our Web App,
so we only need the publishing permissions from this role.
You could make a tighter custom role with only the minimum permissions for publish.

## App registration

Register an app in Entra ID with the following info:

- Name: whatever you want, I used "Seriously Securing Azure PaaS Todos"
- Redirect URIs: Web platform
  - `https://<your-custom-domain>/signin-oidc`: for Azure
  - `https://localhost:7258/signin-oidc`: for local development (you can also make a separate app reg for local)
- Enable ID tokens for Implicit grant and hybrid flows
- Supported account types: "Accounts in any organizational directory"
  - The sample expects the app to be multi-tenant. You can also make it single tenant, you'll just have to set `EntraId__TenantId` app setting in webApp.bicep to your tenant ID

## Deployment script

In order to run the script, you need a config file.
There is a config.sample.json file in the deployment folder that you can rename to "config.json".
Then fill out all of the fields:

- tenantId: Entra ID tenant where we deploy to
- subscriptionId: Azure subscription
- resourceGroup: Name of resource group where we deploy to (does not have to exist, though you'll need to have Owner rights at subscription level then)
- location: Azure region to deploy to
- domainName: Custom domain for the app
- sqlAdminGroupId: Entra ID group ID that will have admin rights to the SQL Managed Instance
- sqlAdminGroupName: Name of that group
- devCenterName: Name for the created Dev Center (required for Managed DevOps Pool)
- devCenterProjectName: Name for project in Dev Center
- azureDevOpsOrganizationUrl: URL for your Azure DevOps organization
- azureDevOpsProjectName: Project in Azure DevOps
- initialManagedHsmAdminObjectId: Most likely your user's object ID in the Entra ID tenant; it will have admin rights to the Managed HSM
- developerIpAddress: Your IP address, used to allow traffic to management VM
- managementVmAdminUsername: Admin account username for management VM
- managementVmAdminSshPublicKeyFilePath: File path to your public SSH key, used for authentication to management VM
- entraIdAuthTenantDomain: Entra ID tenant's domain where you created the app registration (e.g. demos.onmicrosoft.com)
- entraIdClientId: Client ID of that app
- limitedDeveloperUserObjectId: Object ID of the user to be assigned the extremely limited custom developer role

Once you have filled out the file, you can run `deployment/deploy.ps1` to handle most of the deployment.
It will ask you for the HTTPS certificate password.

## DNS

After the deployment is done, you'll need to add a DNS A record that maps the custom domain to the IP address on the Azure Firewall.
If you've done everything correctly, you should get the default App Service page when accessing the domain.

## Management VM scripts

Our environmnet is not quite done yet.
We have components that are network locked and cannot be configured from the outside.
For this purpose the deployment creates an Ubuntu Linux VM.
It allows connections to a public IP address with SSH from the IP address in config.
You wouldn't normally have open SSH ports from a "seriously secured" application.
Use something like Bastion to get more secured access.
Unfortunately I don't have time/budget to setup that for this demo.

The deployment script gives you the VM's IP address.
Connect to it with an SCP client.
Upload the `setup-managedhsm.sh` and `setup-sql.sh` scripts to the home directory.
Now open a terminal over SSH and run these:

```bash
chmod u+x ./setup-managedhsm.sh
chmod u+x ./setup-sql.sh
./setup-managedhsm.sh
./setup-sql.sh
```

What will happen:

- AZ CLI installation
- Login with device code flow
- Subscription selection
- HSM activation, role assignments, key creation
- Sqlcmd installation, SQL user creation, permission assignments

HSM activation can take a couple minutes.

The scripts generate 3 RSA key pairs and they are stored in that home folder.
_Normally_ you would need to store these somewhere very secure.
For the sake of this demo, that's outside of the scope.

## Create Azure DevOps pipeline

After running the deployment script, the DevOps agent pool should be available in Azure DevOps.
The pool name in deployment/pipelines/build-and-release.yaml is updated by the deployment script, so that should be up to date.

You should also have the code in a GitHub repository or Azure DevOps repository to which you have access.

Then we can create the pipeline:

1. Go to Pipelines -> Pipelines
1. Create pipeline / New pipeline
1. Where is your code? Choose your location.
1. Select your repository
1. Configure your pipeline: Existing Azure Pipelines YAML file
1. Branch: main
1. Path: /deployment/pipelines/build-and-release.yaml
1. Continue
1. Save the pipeline

When the pipeline runs for the first time, you will have to approve access to the agent pool and service connection.

Run the pipeline. It will:

1. Create a deployment package
1. Run EF migrations on the SQL database
1. Deploy to the Web App

Now the app should be fully functional.

## Local development

You can specify an Azure Key Vault key + Storage account/emulator to use for Data Protection, but you don't have to.

You do need to configure the Entra ID settings + SQL DB connection string.

Update the SQL database by running these in solution directory:

```bash
dotnet tool restore
dotnet ef database update -s Joonasw.SeriouslySecuringAzurePaas.TodoApp.Web -p Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data
```

## What could be done better

As this is a sample application for a conference presentation and not a real production application, I have taken shortcuts at times.
So there are at least the following things that could be done better to make this truly production-ready:

- Bastion for remote access (the management VM is a backdoor to the spoke VNET currently)
- Hub deployment + common services should be separated from the app spoke and app's resources
- Managed HSM activation RSA keys + security domain should be stored somewhere secure
- SQL permissions could potentially be reduced for the deployment pipeline and app
- Re-enable the two disabled WAF rules and add the required exclusions (cookies and ID tokens etc. often contain characters that might look like SQL injection to the WAF)
