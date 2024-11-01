curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

# Required Enter press
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"

sudo apt-get update
sudo apt-get install sqlcmd

SQL="
CREATE USER [devops-pool-identity-x43ywukzvc6uu] FROM EXTERNAL PROVIDER;
ALTER ROLE db_ddladmin ADD MEMBER [devops-pool-identity-x43ywukzvc6uu];
ALTER ROLE db_datareader ADD MEMBER [devops-pool-identity-x43ywukzvc6uu];
ALTER ROLE db_datawriter ADD MEMBER [devops-pool-identity-x43ywukzvc6uu];

CREATE USER [app-x43ywukzvc6uu] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [app-x43ywukzvc6uu];
ALTER ROLE db_datawriter ADD MEMBER [app-x43ywukzvc6uu];
"
sqlcmd -S "sql-x43ywukzvc6uu.46cc585a7110.database.windows.net" --authentication-method ActiveDirectoryAzCli -d "sqldbx43ywukzvc6uu" -N mandatory -Q "$SQL"