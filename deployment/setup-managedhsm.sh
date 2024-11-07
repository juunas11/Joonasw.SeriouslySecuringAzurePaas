#!/bin/bash

SUBSCRIPTION_ID=f532ecab-6efb-4f51-8848-b7a7e9ab4d6d
HSM_NAME=hsm-app-dp-ykqaksesv6pz4
ADMIN_OBJECT_ID=91a51582-c163-4491-a9da-1b76fbcb906b
WEB_APP_OBJECT_ID=d2a3540d-506e-403e-83e2-451520c765e0
DATA_PROTECTION_KEY_NAME=DataProtectionKeyEncryptionKey
TENANT_ID=0d7e0754-812c-4a0f-883f-5f34cf78d354

ADMIN_ROLE_ASSIGNMENT_ID=$(uuidgen)
WEB_APP_ROLE_ASSIGNMENT_ID=$(uuidgen)

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Azure CLI installed"

# Login to Azure
az login -t "$TENANT_ID"

echo "Logged in to Azure"

# Create certificates for HSM activation (min 3 RSA keys are needed)
# NOTE: Normally you would need to store these extremely securely, you need them for DR purposes
openssl req -newkey rsa:2048 -nodes -keyout cert_0.key -x509 -days 365 -out cert_0.cer -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=SSAP/OU=TodoAppDev/CN=cert0"
openssl req -newkey rsa:2048 -nodes -keyout cert_1.key -x509 -days 365 -out cert_1.cer -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=SSAP/OU=TodoAppDev/CN=cert1"
openssl req -newkey rsa:2048 -nodes -keyout cert_2.key -x509 -days 365 -out cert_2.cer -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=SSAP/OU=TodoAppDev/CN=cert2"

echo "Certificates created for HSM activation"

# Activate HSM
echo "Activating HSM, this will take a moment..."
az keyvault security-domain download --hsm-name "$HSM_NAME" --sd-wrapping-keys ./cert_0.cer ./cert_1.cer ./cert_2.cer --sd-quorum 2 --security-domain-file SSAPHSM-SD.json

echo "HSM activated"

# Assign role to admin so we can create a key
az keyvault role assignment create --hsm-name "$HSM_NAME" --role 'Managed HSM Crypto User' --scope /keys --assignee-object-id "$ADMIN_OBJECT_ID" --assignee-principal-type User -n "$ADMIN_ROLE_ASSIGNMENT_ID"

echo "Role assigned to admin"

# Create data protection key
az keyvault key create --hsm-name "$HSM_NAME" -n "$DATA_PROTECTION_KEY_NAME" --kty RSA-HSM -p hsm --size 4096 --subscription "$SUBSCRIPTION_ID" --ops wrapKey unwrapKey

echo "Data protection key created"

# Assign role to web app so it can use the key
az keyvault role assignment create --hsm-name "$HSM_NAME" --role 'Managed HSM Crypto Service Encryption User' --scope "/keys/$DATA_PROTECTION_KEY_NAME" --assignee-object-id "$WEB_APP_OBJECT_ID" --assignee-principal-type ServicePrincipal -n "$WEB_APP_ROLE_ASSIGNMENT_ID"

echo "Role assigned to web app"