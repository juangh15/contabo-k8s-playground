# Contabo-k8s-playground
Setup of many infrastructure automations to enable internal K8s capabilities for a Contabo VPS instance.
This setup is intended to practice concepts.

## Requirements
* You need a Contabo Instance VPS already created
* You need valid Contabo API credentials

## Generating .contabo_env file
Run this command to generate the .contabo_env file with the Contabo Secrets to enable API auth.

1. Copy the command into a notepad
2. Replace each \<your value> block with your custom values, removing <>.
3. Paste the command on a valid shell and run it to generate the file.
```
echo '''
# From Contabo secrets:
CLIENT_ID="<your Contabo client ID>"
CLIENT_SECRET="<your Contabo client secret>"
API_USER="<your Contabo API user>"
API_PASSWORD="<your Contabo API password>"

# Terraform variables
export TF_VAR_contabo_client_id=$CLIENT_ID
export TF_VAR_contabo_client_secret=$CLIENT_SECRET
export TF_VAR_contabo_api_user=$API_USER
export TF_VAR_contabo_api_password=$API_PASSWORD

# API variables
export CNTB_OAUTH2_CLIENT_ID=$CLIENT_ID
export CNTB_OAUTH2_CLIENT_SECRET=$CLIENT_SECRET
export CNTB_OAUTH2_USER=$API_USER
export CNTB_OAUTH2_PASS=$API_PASSWORD
''' > ./.contabo_env
```
4. Run the following command to load the Contabo environment variables:
```
source ./.contabo_env
```

## Provisioning Infrastructure
Go to terraform folder to start provisioning the infrastructure resources.