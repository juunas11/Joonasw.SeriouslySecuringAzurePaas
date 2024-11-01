# Joonasw.SeriouslySecuringAzurePaas

Demo for Cloudbrew 2024

A certificate is needed to encrypt the connections between users and the Application Gateway.
I used Let's Encrypt through an ACME client to get one (90 days more than enough to be valid until the conference is done).
The certificate is expected in "deployment/cert.pfx".

The "EnableApplicationGatewayNetworkIsolation" preview flag must be currently enabled on the subscription to deploy the Application Gateway WAF with no public endpoints.

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

TODO: Check what role we need for the SP. Update below.

Add the Owner role to the created app.

On the Conditions tab, there is a choice "What user can do".
To be most restrictive in this case, you can limit the app to only be able to assign the following roles:

- Key Vault Crypto Service Encryption User
- Storage Blob Data Contributor

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

When the pipeline runs for the first time, you will have to approve access to the agent pool.

## Create Entra ID app registration

The app uses Entra ID for authentication and thus requires an app registration.

Register an app with the following details:

- Redirect URIs
  - Web platform
  - `https://localhost:7258/signin-oidc`
  - `https://your-app-domain/signin-oidc`
  - In production you should make separate app registrations for development and production use
- Add a self-signed certificate for authentication

## Management VM

An Ubuntu virtual machine is setup for troubleshooting and management by default.
It allows connections to a public IP address with SSH from the IP address in config.
You wouldn't normally have open SSH ports from a "seriously secured" application.
Use something like Bastion to get more secured access.
Unfortunately I don't have time/budget to setup that for this demo.

## Local development

`dotnet ef database update -s Joonasw.SeriouslySecuringAzurePaas.TodoApp.Web -p Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data`
