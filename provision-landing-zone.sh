# This is a script for provisioning resources and services for DEV, UAT and PROD environments for aetl in the Azure cloud. All resources and services are created in a resource group under one vnet, with each service in its own subnet.

# Below are steps of provisioning:
# 1. Create a resource grouop
# 2. Create a vnet
# 3. Create a key vault
# 4. Create a storage account
# 5. Create a log analytics workspace
# 6. Create a private DNS zone
# 7. Create a jumpbox
# 8. Create a Azure SQL database
# 9. Create a private endpoint for the database
# 10. Create an App Service Plan
# 11. Create an App Service
# 12. Create an Application Gateway before the App Service
# 13. Create an App Service inbound and outbound subnets

### Below are the parameters for provisioning:
# Resource group name, Location, Vnet

# Default environment is dev
ENV=${1:-dev}

if [ "$ENV" == "dev" ]; then
    IP_PREFIX=10.100
elif [ "$ENV" == "uat" ]; then
    IP_PREFIX=10.101
elif [ "$ENV" == "prod" ]; then
    IP_PREFIX=10.102
else
    echo "Invalid environment. Please set ENV to dev, uat, or prod."
    exit 1
fi

echo "IP_PREFIX is set to $IP_PREFIX"
RESOURCE_GROUP=rg-aetl-hk-ucp-${ENV}
REGION=eastasia
VNET_NAME=vnet-aetl-hk-ucp-${ENV}-01
VNET_ADDRESS_PREFIX=${IP_PREFIX}.0.0/20

# Key Vault name
KV_NAME=kv-aetl-hk-ucp-${ENV}-01

# SSL certs
ZKPYTUGCOM_CERT=zkpytugcom
ZKPYTUGCOM_CERT_PASSWORD=password
ZKPYTUGCOM_HOSTNAMES="zkpytug.com *.zkpytug.com"

# App services
APP1_NAME=app-aetl-hk-ucp-${ENV}-01
APP1_IMAGE=mcr.microsoft.com/azuredocs/aci-helloworld:latest

# App services plan
APP_SERVICE_PLAN_NAME=asp-aetl-hk-ucp-${ENV}-01
APP_SERVICE_PLAN_SKU=P2V3
APP_SERVICE_PLAN_SIZE=P2V3
APP_SERVICE_PLAN_WORKER_SIZE=1
APP_SERVICE_PLAN_WORKER_COUNT=1
APP_SERVICE_PLAN_LOCATION=eastasia
APP_SERVICE_PLAN_RESOURCE_GROUP=rg-aetl-hk-ucp-${ENV}

APP1_INBOUND_SUBNET_NAME=snet-aetl-hk-ucp-app-${ENV}-01
APP1_INBOUND_SUBNET_NSG=nsg-aetl-hk-ucp-app-${ENV}-01
APP1_INBOUND_SUBNET_PREFIX=${IP_PREFIX}.4.128/27
APP1_OUTBOUND_SUBNET_NAME=snet-aetl-hk-ucp-app-${ENV}-02
APP1_OUTBOUND_SUBNET_NSG=nsg-aetl-hk-ucp-app-${ENV}-02
APP1_OUTBOUND_SUBNET_PREFIX=${IP_PREFIX}.4.160/27
APP1_PRIVATE_ENDPOINT_NAME=pe-aetl-hk-ucp-app-${ENV}-01

# MYSQL
SQL_SERVER_NAME=sql-aetl-hk-ucp-${ENV}-01
SQL_DATABASE_NAME=sqldb-aetl-hk-ucp-${ENV}-01
SQL_ADMIN_USERNAME=sqladmin
SQL_ADMIN_PASSWORD=Password1234
SQL_SUBNET_NAME=snet-aetl-hk-ucp-sql-${ENV}-01
SQL_SUBNET_PREFIX=${IP_PREFIX}.4.32/27
SQL_NSG_NAME=nsg-aetl-hk-ucp-sql-${ENV}-01
SQL_ROUTE_TABLE_NAME=rt-aetl-hk-ucp-sql-${ENV}-01
SQL_ENDPOINT_NAME=pe-aetl-hk-ucp-sql-${ENV}-01

# Windows Jumpbox

VM_NAME=vmucpadm${ENV}01
VM_SUBNET_NAME=snet-aetl-hk-ucp-adm-${ENV}-01
VM_SUBNET_PREFIX=${IP_PREFIX}.4.96/27
VM_NSG_NAME=nsg-aetl-hk-ucp-adm-${ENV}-01
VM_ROUTE_TABLE_NAME=rt-aetl-hk-ucp-adm-${ENV}-01
VM_SIZE=Standard_B2s
VM_STATIC_IP=${IP_PREFIX}.4.100

# Application gateway
APPGW_NAME=agw-aetl-hk-ucp-${ENV}-01
APPGW_IDENTITY=id-aetl-hk-ucp-${ENV}-01
APPGW_PREFIX=${IP_PREFIX}.5.0/27
APPGW_PRIVATE_IP=${IP_PREFIX}.5.10
APPGW_SUBNET_NAME=snet-aetl-hk-ucp-agw-${ENV}-01
APPGW_PUBLIC_IP_NAME=pip-agw-aetl-hk-ucp-${ENV}-01
APPGW_WAF_POLICY_NAME=wafp-aetl-hk-ucp-${ENV}-01
APPGW_NSG_NAME=nsg-aetl-hk-ucp-agw-${ENV}-01
APPGW_ROUTE_TABLE_NAME=rt-aetl-hk-ucp-agw-${ENV}-01

# Private DNS
DNS_ZONE_NAME_1=privatelink.azurewebsites.net
DNS_ZONE_NAME_3=zkpytug.com
DNS_ZONE_NAME_4=privatelink.redis.cache.windows.net
DNS_ZONE_NAME_5=privatelink.blob.core.windows.net
DNS_ZONE_NAME_6=privatelink.file.core.windows.net
DNS_ZONE_NAME_7=privatelink.database.windows.net

MISC_SUBNET_NAME=snet-aetl-hk-ucp-misc-${ENV}-01
MISC_SUBNET_PREFIX=${IP_PREFIX}.5.32/27
MISC_NSG_NAME=nsg-aetl-hk-ucp-misc-${ENV}-01
MISC_ROUTE_TABLE_NAME=rt-aetl-hk-ucp-misc-${ENV}-01

# Log Analytics Workspace name
LOG_ANALYTICS_WORKSPACE_NAME=log-aetl-hk-ucp-${ENV}-01

# App Insights name
APP_INSIGHTS_NAME=appi-aetl-hk-ucp-${ENV}-01

AZURE_MONITORING_WORKSPACE_NAME=azmon-rci-rhk-ucp-${ENV}-01
AZURE_MONITORING_WORKSPACE_LOCATION=eastasia

# Storage Persistent Volume
STORAGE_ACCOUNT_NAME=storaetlhkucp${ENV}
STORAGE_SUBNET_NAME=snet-aetl-hk-ucp-stor-${ENV}-01
STORAGE_SUBNET_PREFIX=${IP_PREFIX}.4.64/27
STORAGE_CONTAINER_NAME=con01
STORAGE_BLOB_NAME=blob01
STORAGE_BLOB_FILE=blobfile01
STORAGE_SHARE_NAME=fs01
STORAGE_ENDPOINT_NAME_BLOB=pe-aetl-hk-ucp-stor-blob-${ENV}-01
STORAGE_ENDPOINT_NAME_FILESHARE=pe-aetl-hk-ucp-stor-fileshare-${ENV}-01
STORAGE_NSG_NAME=nsg-aetl-hk-ucp-stor-${ENV}-01
STORAGE_ROUTE_TABLE_NAME=rt-aetl-hk-ucp-stor-${ENV}-01

# create resource group
echo "Creating resource group $RESOURCE_GROUP in $REGION"
az group create --name $RESOURCE_GROUP --location $REGION

# create vnet
echo "Creating vnet $VNET_NAME in $REGION"
az network vnet create --name $VNET_NAME --resource-group $RESOURCE_GROUP --location $REGION --address-prefixes $VNET_ADDRESS_PREFIX

# create key vault
echo "Creating key vault $KV_NAME in $REGION"
az keyvault create --name $KV_NAME --resource-group $RESOURCE_GROUP --location $REGION

# generate pfx from crt and key
# openssl pkcs12 -export -out $ZKPYTUGCOM_CERT.pfx -inkey $ZKPYTUGCOM_CERT.key -in $ZKPYTUGCOM_CERT.crt -password pass:$ZKPYTUGCOM_CERT_PASSWORD

# upload cert to key vault
echo "Uploading certificate $ZKPYTUGCOM_CERT to key vault $KV_NAME"
az keyvault certificate import --vault-name $KV_NAME --name $ZKPYTUGCOM_CERT --file $ZKPYTUGCOM_CERT.pfx --password $ZKPYTUGCOM_CERT_PASSWORD

# create a db secret in the key vault
echo "Creating a secret sqladmin in key vault $KV_NAME"
az keyvault secret set --vault-name $KV_NAME --name "sqladmin" --value "Password1234"

# create private DNS zone
echo "Creating private DNS zones"
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_1
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_3
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_4
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_5
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_6
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $DNS_ZONE_NAME_7

# create private DNS link
echo "Creating private DNS link"
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_1 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_3 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_4 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_5 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_6 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME_7 --name $VNET_NAME --virtual-network $VNET_NAME --registration-enabled false

# Create a storage account with ZRS replication
echo "Creating storage account $STORAGE_ACCOUNT_NAME in $REGION"
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --location $REGION --sku Standard_ZRS

# create blob container
echo "Creating blob container $STORAGE_CONTAINER_NAME in storage account $STORAGE_ACCOUNT_NAME"
az storage container create --name $STORAGE_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

# get storage account id
STORAGE_ACCOUNT_ID=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
echo "STORAGE_ACCOUNT_ID: $STORAGE_ACCOUNT_ID"

# create fileshare
echo "Creating fileshare $STORAGE_SHARE_NAME in storage account $STORAGE_ACCOUNT_NAME"
az storage share create --name $STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --quota 10

# create private endpoint for the storage account
echo "Creating private endpoint for the storage account $STORAGE_ACCOUNT_NAME"
az network vnet subnet create --name $STORAGE_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefix $STORAGE_SUBNET_PREFIX
echo "Creating network security group $STORAGE_NSG_NAME"
az network nsg create --name $STORAGE_NSG_NAME --resource-group $RESOURCE_GROUP --location $REGION
az network nsg rule create --name Allow-All-Outbound --nsg-name $STORAGE_NSG_NAME --resource-group $RESOURCE_GROUP --priority 100 --protocol '*' --direction Outbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow
az network vnet subnet update --name $STORAGE_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --network-security-group $STORAGE_NSG_NAME

echo "Creating Storage Private Endpoint for Blob"
az network private-endpoint create --name $STORAGE_ENDPOINT_NAME_BLOB --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --subnet $STORAGE_SUBNET_NAME --private-connection-resource-id $STORAGE_ACCOUNT_ID --connection-name $STORAGE_ENDPOINT_NAME_BLOB --location $REGION --group-ids blob
az network private-endpoint dns-zone-group create --resource-group $RESOURCE_GROUP --endpoint-name $STORAGE_ENDPOINT_NAME_BLOB --name zone-group --private-dns-zone $DNS_ZONE_NAME_5 --zone-name blob

# create a private endpoint for fileshare
echo "Creating Storage Private Endpoint for Fileshare"
az network private-endpoint create --name $STORAGE_ENDPOINT_NAME_FILESHARE --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --subnet $STORAGE_SUBNET_NAME --private-connection-resource-id $STORAGE_ACCOUNT_ID --connection-name $STORAGE_ENDPOINT_NAME_FILESHARE --location $REGION --group-ids file
az network private-endpoint dns-zone-group create --resource-group $RESOURCE_GROUP --endpoint-name $STORAGE_ENDPOINT_NAME_FILESHARE --name zone-group --private-dns-zone $DNS_ZONE_NAME_6 --zone-name file

# create log analytics workspace
echo "Creating log analytics workspace $LOG_ANALYTICS_WORKSPACE_NAME in $REGION"
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME --location $REGION

# create jumpbox
#Create VM with a static Public IP address and static private IP address
az network public-ip create --resource-group $RESOURCE_GROUP --name $VM_NAME-pip --sku Standard --allocation-method static --location $REGION
#Create VM_SUBNET_NAME
az network vnet subnet create -g $RESOURCE_GROUP --vnet-name $VNET_NAME -n $VM_SUBNET_NAME --address-prefixes $VM_SUBNET_PREFIX
az network nic create --resource-group $RESOURCE_GROUP --name $VM_NAME-nic --vnet-name $VNET_NAME --subnet $VM_SUBNET_NAME --public-ip-address $VM_NAME-pip --private-ip-address $VM_STATIC_IP
echo "Creating VM"
az vm create --resource-group $RESOURCE_GROUP --name $VM_NAME --image Win2022Datacenter --admin-username azureuser --admin-password Password1234 --nics $VM_NAME-nic --size $VM_SIZE --location $REGION

# create nsg for vm
echo "Creating NSG for VM"
az network nsg create --name $VM_NSG_NAME --resource-group $RESOURCE_GROUP --location $REGION
# attach nsg to vm subnet
az network vnet subnet update -g $RESOURCE_GROUP --vnet-name $VNET_NAME -n $VM_SUBNET_NAME --network-security-group $VM_NSG_NAME
# allow all inbound 3389
az network nsg rule create --name AllowRDP --nsg-name $VM_NSG_NAME --resource-group $RESOURCE_GROUP --access Allow --direction Inbound --priority 100 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 3389 --protocol Tcp

# create Azure SQL database
echo "Creating Azure SQL database $SQL_DATABASE_NAME in $REGION"
az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --location $REGION --admin-user $SQL_ADMIN_USERNAME --admin-password $SQL_ADMIN_PASSWORD
#az sql db create --name $SQL_DATABASE_NAME --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --service-objective S0 --backup-storage-redundancy Zone

# Create a serverless database
az sql db create  --name $SQL_DATABASE_NAME --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --edition GeneralPurpose --compute-model Serverless --family Gen5 --capacity 1 --auto-pause-delay 120

az sql db tde set --status Enabled --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --database $SQL_DATABASE_NAME

# create sql server private end point
sql_server_id=$(az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --location $REGION --admin-user $SQL_ADMIN_USERNAME --admin-password $SQL_ADMIN_PASSWORD --enable-public-network true --query id -o tsv)
echo "SQL Server ID: $sql_server_id"
echo "Creating SQL Private Endpoint"
az network private-endpoint create --name $SQL_ENDPOINT_NAME --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --subnet $SQL_SUBNET_NAME --private-connection-resource-id $sql_server_id --connection-name $SQL_ENDPOINT_NAME --location $REGION --group-ids sqlServer
# link private end point with private dns zone
az network private-endpoint dns-zone-group create --resource-group $RESOURCE_GROUP --endpoint-name $SQL_ENDPOINT_NAME --name zone-group --private-dns-zone $DNS_ZONE_NAME_7 --zone-name sql

# create private endpoint for the database
echo "Creating private endpoint for the database $SQL_SERVER_NAME"
az network vnet subnet create --name $SQL_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefix $SQL_SUBNET_PREFIX

echo "Creating network security group $SQL_NSG_NAME"
az network nsg create --name $SQL_NSG_NAME --resource-group $RESOURCE_GROUP --location $REGION
az network nsg rule create --name Allow-SQL --nsg-name $SQL_NSG_NAME --resource-group $RESOURCE_GROUP --priority 100 --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 1433 --access Allow
az network nsg rule create --name Allow-All-Outbound --nsg-name $SQL_NSG_NAME --resource-group $RESOURCE_GROUP --priority 100 --protocol '*' --direction Outbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow
az network vnet subnet update --name $SQL_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --network-security-group $SQL_NSG_NAME

# create App Service Plan
echo "Creating App Service Plan $APP_SERVICE_PLAN_NAME in $REGION"
az appservice plan create --name $APP_SERVICE_PLAN_NAME --resource-group $APP_SERVICE_PLAN_RESOURCE_GROUP --location $APP_SERVICE_PLAN_LOCATION --sku $APP_SERVICE_PLAN_SKU --is-linux

# create App Service
echo "Creating App Service $APP1_NAME in $REGION"
az webapp create --name $APP1_NAME --plan $APP_SERVICE_PLAN_NAME --resource-group $RESOURCE_GROUP --deployment-container-image-name $APP1_IMAGE

az webapp config appsettings list --name $APP1_NAME --resource-group $RESOURCE_GROUP

az webapp identity assign --name $APP1_NAME --resource-group $RESOURCE_GROUP
APP1_PRINCIPAL_ID=$(az webapp identity show --name $APP1_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)
echo "APP1_PRINCIPAL_ID: $APP1_PRINCIPAL_ID"

# allow the App Service to access the database
#echo "Setting app settings for $APP1_NAME"
#az webapp config appsettings set --name $APP1_NAME --resource-group $RESOURCE_GROUP --settings "SQL_SERVER_NAME=$SQL_SERVER_NAME" "SQL_DATABASE_NAME=$SQL_DATABASE_NAME" "SQL_ADMIN_USERNAME=$SQL_ADMIN_USERNAME" "SQL_ADMIN_PASSWORD=$SQL_ADMIN_PASSWORD"

# allow the App Service to access key vault
echo "Setting key vault policy for $APP1_NAME"
az keyvault set-policy --name $KV_NAME --object-id $APP1_PRINCIPAL_ID --secret-permissions get list

# create App Service inbound and outbound subnets
echo "Creating subnets for App Service $APP1_NAME"
az network vnet subnet create --name $APP1_INBOUND_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefix $APP1_INBOUND_SUBNET_PREFIX

echo "Creating network security group $APP1_INBOUND_SUBNET_NSG"
az network nsg create --name $APP1_INBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --location $REGION
az network nsg rule create --name Allow-HTTP --nsg-name $APP1_INBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --priority 100 --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow
az network nsg rule create --name Allow-HTTPS --nsg-name $APP1_INBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --priority 101 --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443 --access Allow
az network nsg rule create --name Allow-All-Outbound --nsg-name $APP1_INBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --priority 100 --protocol '*' --direction Outbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow

echo "Updating subnet $APP1_INBOUND_SUBNET_NAME with network security group $APP1_INBOUND_SUBNET_NSG"
az network vnet subnet update --name $APP1_INBOUND_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --network-security-group $APP1_INBOUND_SUBNET_NSG

echo "Creating subnet $APP1_OUTBOUND_SUBNET_NAME"
az network vnet subnet create --name $APP1_OUTBOUND_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefix $APP1_OUTBOUND_SUBNET_PREFIX

az network nsg create --name $APP1_OUTBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --location $REGION
az network nsg rule create --name Allow-All-Outbound --nsg-name $APP1_OUTBOUND_SUBNET_NSG --resource-group $RESOURCE_GROUP --priority 100 --protocol '*' --direction Outbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow

echo "Updating subnet $APP1_OUTBOUND_SUBNET_NAME with network security group $APP1_OUTBOUND_SUBNET_NSG"
az network vnet subnet update --name $APP1_OUTBOUND_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --network-security-group $APP1_OUTBOUND_SUBNET_NSG

# create private endpoint for the App Service
APP1_ID=$(az webapp show --name $APP1_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)
echo "APP1_ID: $APP1_ID"

echo "Creating private endpoint for the App Service $APP1_NAME"
az network private-endpoint create --name $APP1_PRIVATE_ENDPOINT_NAME --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --subnet $APP1_INBOUND_SUBNET_NAME --private-connection-resource-id $APP1_ID --group-id sites --connection-name $APP1_PRIVATE_ENDPOINT_NAME --location $REGION

echo "Creating private endpoint DNS zone group for the App Service $APP1_NAME"
az network private-endpoint dns-zone-group create --resource-group $RESOURCE_GROUP --endpoint-name $APP1_PRIVATE_ENDPOINT_NAME --name zone-group --private-dns-zone $DNS_ZONE_NAME_1 --zone-name sites

# enable public access to App Service
echo "Enabling public access to App Service $APP1_NAME"
az resource update -g $RESOURCE_GROUP -n $APP1_NAME --resource-type Microsoft.Web/sites --set properties.publicNetworkAccess=Enabled

############################################################################################# 1 Configure SSL
echo "Creating App Gateway Public IP"
az network public-ip create -n $APPGW_PUBLIC_IP_NAME -g $RESOURCE_GROUP --allocation-method Static --sku Standard --zone 1 2 3

echo "Creating App Gateway Subnet"
az network vnet subnet create -g $RESOURCE_GROUP --vnet-name $VNET_NAME -n $APPGW_SUBNET_NAME --address-prefixes $APPGW_PREFIX

echo "Creating App Gateway"
az network application-gateway create -n $APPGW_NAME -g $RESOURCE_GROUP --sku Standard_v2 --public-ip-address $APPGW_PUBLIC_IP_NAME --private-ip-address $APPGW_PRIVATE_IP --vnet-name $VNET_NAME --subnet $APPGW_SUBNET_NAME --priority 100 --zones 1

echo "APPGW_PRIVATE_IP $APPGW_PRIVATE_IP"

APPGW_IDENTITY_ID=$(az identity create --name $APPGW_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
echo "APPGW_IDENTITY_ID $APPGW_IDENTITY_ID"

az network application-gateway identity assign -g $RESOURCE_GROUP --gateway-name $APPGW_NAME --identity $APPGW_IDENTITY_ID
APPGW_IDENTITY_PRINCIPAL_ID=$(az identity show --name $APPGW_NAME --resource-group $RESOURCE_GROUP --query principalId -o tsv)
echo "APPGW_IDENTITY_PRINCIPAL_ID $APPGW_IDENTITY_PRINCIPAL_ID"

# assign role to appgw identity
echo "Assigning role to appgw identity"
az keyvault set-policy --name $KV_NAME --resource-group $RESOURCE_GROUP --secret-permissions all --certificate-permissions all --key-permissions all --object-id $APPGW_IDENTITY_PRINCIPAL_ID

# import ssl cert to appgw from key vault
echo "Importing SSL cert to appgw from key vault"
az network application-gateway ssl-cert create --gateway-name $APPGW_NAME --name $ZKPYTUGCOM_CERT --resource-group $RESOURCE_GROUP --key-vault-secret-id $(az keyvault secret show --vault-name $KV_NAME --name $ZKPYTUGCOM_CERT --query id -o tsv)

# upload SSL certs to app gateway
echo "Uploading SSL certs to app gateway"
az network application-gateway ssl-cert create --gateway-name $APPGW_NAME --resource-group $RESOURCE_GROUP --name $ZKPYTUGCOM_CERT --cert-file $ZKPYTUGCOM_CERT.pfx --cert-password $ZKPYTUGCOM_CERT_PASSWORD

############################################################################################# 2 Configure Front-End Port
# create a frontend port
echo "Creating frontend port"
az network application-gateway frontend-port create --gateway-name $APPGW_NAME --name appGatewayFrontendPort443 --resource-group $RESOURCE_GROUP --port 443

# get app gateway frontend ip configuration
echo "Getting app gateway frontend ip configuration"
APPGW_FRONTEND_IP_ID=$(az network application-gateway frontend-ip show --gateway-name $APPGW_NAME --resource-group $RESOURCE_GROUP --name appGatewayFrontendIP --query id -o tsv)

# create app gateway https listener with public ip multi-site hosttype
echo "Creating app gateway https listener"
az network application-gateway http-listener create --gateway-name $APPGW_NAME --name appGatewayHttpsListeneraetlHk --resource-group $RESOURCE_GROUP --frontend-port appGatewayFrontendPort443 --frontend-ip $APPGW_FRONTEND_IP_ID --host-names $ZKPYTUGCOM_HOSTNAMES --ssl-cert $ZKPYTUGCOM_CERT

############################################################################################# 3 Configure Back-End Pool, Health Probe, HTTP Settings, and Rule
# get App Service private FQDN
APP1_PRIVATE_IP=$(az network private-endpoint show --name $APP1_PRIVATE_ENDPOINT_NAME --resource-group $RESOURCE_GROUP --query 'customDnsConfigs[0].ipAddresses' -o tsv)

# get FQDN of the App Service
APP1_FQDN=$(az webapp show --name $APP1_NAME --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)
echo "APP1_FQDN: $APP1_FQDN"

# create backend settings for app service
echo "Creating backend settings for app service"
# get internal ip of app service
az network application-gateway address-pool create --gateway-name $APPGW_NAME --name appGatewayBackendPoolaetlHk --resource-group $RESOURCE_GROUP --servers $APP1_FQDN

# create health probe for app service
echo "Creating health probe for app service"
az network application-gateway probe create --gateway-name $APPGW_NAME --name appGatewayBackendHealthaetlHk --resource-group $RESOURCE_GROUP --path / --protocol Https --host $APP1_FQDN --interval 30 --timeout 30 --threshold 3

# create http-settings for app service
echo "Creating http settings for app service"
az network application-gateway http-settings create --gateway-name $APPGW_NAME --name appGatewayBackendHttpSettingsaetlHk --resource-group $RESOURCE_GROUP --port 443 --protocol Https --cookie-based-affinity Disabled --timeout 30 --probe appGatewayBackendHealthaetlHk --host-name $APP1_FQDN

############################################################################################# 4 Configure Rule
# create a rule for app service
az network application-gateway rule create --gateway-name $APPGW_NAME --name appGatewayRuleaetlHk --resource-group $RESOURCE_GROUP --http-listener appGatewayHttpsListeneraetlHk --address-pool appGatewayBackendPoolaetlHk --http-settings appGatewayBackendHttpSettingsaetlHk --priority 190

############################################################################################# 5 Configure Redirect Rule
az network application-gateway http-listener create --gateway-name $APPGW_NAME --name appGatewayHttpListeneraetlHk --resource-group $RESOURCE_GROUP --frontend-port appGatewayFrontendPort --frontend-ip $APPGW_FRONTEND_IP_ID --host-names $ZKPYTUGCOM_HOSTNAMES

az network application-gateway redirect-config create --gateway-name $APPGW_NAME --name appGatewayRedirectConfigaetlHk --resource-group $RESOURCE_GROUP --type Permanent --include-query-string true --target-listener appGatewayHttpsListeneraetlHk

az network application-gateway rule delete --gateway-name $APPGW_NAME --name rule1 --resource-group $RESOURCE_GROUP

az network application-gateway rule create --gateway-name $APPGW_NAME --name RedirectHttpToHttpsaetlHk --resource-group $RESOURCE_GROUP --http-listener appGatewayHttpListeneraetlHk --redirect-config appGatewayRedirectConfigaetlHk --priority 290


# create log analytics workspace
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME --location $REGION

# create app insights
az monitor app-insights component create --app $APP_INSIGHTS_NAME --location $REGION --resource-group $RESOURCE_GROUP --application-type web --kind web --tags "env=$ENV" --workspace $LOG_ANALYTICS_WORKSPACE_NAME

function delete_group() {
  az group delete --name $RESOURCE_GROUP --yes
}

function stop_appgw() {
  az network application-gateway stop --name $APPGW_NAME --resource-group $RESOURCE_GROUP
}

function start_appgw() {
  az network application-gateway start --name $APPGW_NAME --resource-group $RESOURCE_GROUP
}

function delete_appgw() {
  az network application-gateway delete --name $APPGW_NAME --resource-group $RESOURCE_GROUP
}

function stop_webapp() {
  az webapp stop --name $APP1_NAME --resource-group $RESOURCE_GROUP
}

function start_webapp() {
  az webapp start --name $APP1_NAME --resource-group $RESOURCE_GROUP
}

function delete_webapp() {
  az webapp delete --name $APP1_NAME --resource-group $RESOURCE_GROUP
}

function stop_vm() {
  az vm stop --name $VM_NAME --resource-group $RESOURCE_GROUP
  az vm deallocate --name $VM_NAME --resource-group $RESOURCE_GROUP
}

function start_vm() {
  az vm start --name $VM_NAME --resource-group $RESOURCE_GROUP
}

function delete_vm() {
  az vm delete --name $VM_NAME --resource-group $RESOURCE_GROUP --yes
}

function delete_resources() {
  delete_group
  #purge deleted key vault
  az keyvault purge --name $KV_NAME
}

function delete_database() {
  az sql db delete --name $SQL_DATABASE_NAME --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --yes
  az sql server delete --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --yes
}
