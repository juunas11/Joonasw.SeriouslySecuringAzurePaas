#!/bin/bash

SUBSCRIPTION_ID=f532ecab-6efb-4f51-8848-b7a7e9ab4d6d
HSM_NAME=kv-app-dp-x43ywukzvc6uu
ADMIN_OBJECT_ID=91a51582-c163-4491-a9da-1b76fbcb906b
WEB_APP_OBJECT_ID=04e32483-2fd0-4b92-8513-a3c00046b9a0
DATA_PROTECTION_KEY_NAME=DataProtectionKeyEncryptionKey

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login -t "$TENANT_ID"

# Create certificates for HSM activation (min 3 RSA keys are needed)
# NOTE: Normally you would need to store these extremely securely, you need them for DR purposes
# TODO: These all required input, could we add them as params so we don't have to type them in?
openssl req -newkey rsa:2048 -nodes -keyout cert_0.key -x509 -days 365 -out cert_0.cer
openssl req -newkey rsa:2048 -nodes -keyout cert_1.key -x509 -days 365 -out cert_1.cer
openssl req -newkey rsa:2048 -nodes -keyout cert_2.key -x509 -days 365 -out cert_2.cer

# TODO: Random guids for role assignment names
# TODO: Use variables
# TODO: Replace variables in deploy script

# Activate HSM
az keyvault security-domain download --hsm-name kv-app-dp-x43ywukzvc6uu --sd-wrapping-keys ./cert_0.cer ./cert_1.cer ./cert_2.cer --sd-quorum 2 --security-domain-file SSAPHSM-SD.json
# Assign role to admin so we can create a key
az keyvault role assignment create --role 'Managed HSM Crypto User' --scope /keys --assignee-object-id 91a51582-c163-4491-a9da-1b76fbcb906b --assignee-principal-type User -n 29d5d763-7ee3-4831-b28d-741a89830a5c --hsm-name kv-app-dp-x43ywukzvc6uu
# Create data protection key
az keyvault key create -n DataProtectionKeyEncryptionKey --kty RSA-HSM -p hsm --size 4096 --hsm-name kv-app-dp-x43ywukzvc6uu --subscription f532ecab-6efb-4f51-8848-b7a7e9ab4d6d --ops wrapKey unwrapKey
# Assign role to web app so it can use the key
az keyvault role assignment create --role 'Managed HSM Crypto Service Encryption User' --scope /keys/DataProtectionKeyEncryptionKey --assignee-object-id 04e32483-2fd0-4b92-8513-a3c00046b9a0 --assignee-principal-type ServicePrincipal -n b67b9667-65b2-4361-89c0-37a526ea81d0 --hsm-name kv-app-dp-x43ywukzvc6uu
