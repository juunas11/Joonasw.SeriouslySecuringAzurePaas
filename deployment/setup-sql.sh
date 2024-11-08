#!/bin/bash

DEVOPS_POOL_IDENTITY_NAME=devops-pool-identity-sta2mwuuor22u
WEB_APP_NAME=app-sta2mwuuor22u
SQL_SERVER_FQDN=sql-sta2mwuuor22u.7d136ca31c3f.database.windows.net
SQL_DATABASE_NAME=sqldbsta2mwuuor22u

curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

# Required Enter press
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"

sudo apt-get update
sudo apt-get install sqlcmd

echo "SQLCMD installed"

# TODO: Could we reduce these permissions?
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