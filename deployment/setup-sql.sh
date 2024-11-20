#!/bin/bash

DEVOPS_POOL_IDENTITY_NAME=devops-pool-identity-6m6nmi7gfho3s
WEB_APP_NAME=app-6m6nmi7gfho3s
SQL_SERVER_FQDN=sql-6m6nmi7gfho3s.9154d7e0fc5b.database.windows.net
SQL_DATABASE_NAME=sqldb6m6nmi7gfho3s

curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

# Required Enter press
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"

sudo apt-get update
sudo apt-get install sqlcmd

echo "SQLCMD installed"

SQL="
CREATE USER [$DEVOPS_POOL_IDENTITY_NAME] FROM EXTERNAL PROVIDER;
ALTER ROLE db_ddladmin ADD MEMBER [$DEVOPS_POOL_IDENTITY_NAME];
ALTER ROLE db_datareader ADD MEMBER [$DEVOPS_POOL_IDENTITY_NAME];
ALTER ROLE db_datawriter ADD MEMBER [$DEVOPS_POOL_IDENTITY_NAME];

CREATE USER [$WEB_APP_NAME] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$WEB_APP_NAME];
ALTER ROLE db_datawriter ADD MEMBER [$WEB_APP_NAME];
"
sqlcmd -S "$SQL_SERVER_FQDN" -d "$SQL_DATABASE_NAME" --authentication-method ActiveDirectoryAzCli -N mandatory -Q "$SQL"

echo "SQL users created for web app and DevOps pool identity"