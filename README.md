# Contabo-k8s-playground
Setup of many infrastructure automations to enable internal K8s capabilities for a Contabo VPS instance.
This setup is intended to practice concepts.

## Requirements
* You need a Contabo Instance VPS already created
* You need valid Contabo API credentials

## Generating .contabo_env file
Run this command on the current path to generate the ***.contabo_env*** file with the Contabo Secrets to enable API auth.

1. Run the command:
    ```
    cp -f ./.exampleenv ./.contabo_env
    ```
2. Open the newly created: ***.contabo_env*** file and replace **REQUIRED** block with your Contabo secrets.  
   Example with nano:
    ```
    nano ./.contabo_env
    ```
    Apply the changes with: CTRL + O > ENTER > CTRL + X
      
3. Run the following command to load the Contabo environment variables:
    ```
    source ./.contabo_env
    ```

## Provisioning Infrastructure
Go to terraform folder to start provisioning the infrastructure resources.