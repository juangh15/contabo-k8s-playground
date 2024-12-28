# Run the command

Change ```environment_path``` to your current playground folder.
For example from "contabo-k8s-playground" directory run:
```
environment_path=./terraform/environments/playground
cd $environment_path
```

# Steps

## 1. Get the current **instance Id**:
Go to Contabo VPS web page and note the **IP Address** of the instance you want to use.  
Then open a shell session and choose one option: 
* Option 1\. Manually store instanceId as a variable.  
    * Use: ```cntb get instances``` command and note the **INSTANCEID** number of the instance matching your **IP Address**.  
    * Use: ```instanceId=123456``` command, replacing ```123456``` with your **INSTANCEID** to save it as a variable.  
* Option 2\. Get instanceId with given IP Address.  
    Use this command by replacing ```123.123.123.123``` with your **IP Address**:  
    
    ```
    ipAddress="123.123.123.123"
    instanceId=$(cntb get instances --output json | jq -r '.[] | select(.ipv4=='\"$ipAddress\"') | ."instanceId"')
    echo $instanceId
    ```   
* Option 3\. Get instanceId with given Display Name, if your instance has a **DISPLAY NAME** already configured.   
    Use this command by replacing ```MainVPS``` with your **DISPLAY NAME**:  

    ```
    ipAddress="MainVPS"
    instanceId=$(cntb get instances --output json | jq -r '.[] | select(.displayName=='\"$ipAddress\"') | ."instanceId"')
    echo $instanceId
    ```  
## 2. Init and upgrade terraform providers:
```
terraform init --upgrade
```  
## 3. Import the existing instance to terraform state:
Use this command to import the ```$instanceId``` we previously got:
```
terraform import module.deploy_main_vps_instances.contabo_instance.main_vps $instanceId
```  
* #### 3.1. **Only in case of failure when importing**:  
    Remove the **main_vps** instance from state. Take extreme care when using this command:  
    ```
    terraform state rm module.deploy_main_vps_instances.contabo_instance.main_vps
    ```  

## 4. Make your changes to main.tf and plan:
Validate all parameters are in place of main.tf and run the command:
```
terraform plan
```
Validate all the changes are correct before proceed with next steps.

## 5. Apply the changes:
This command will apply the infrastructure changes:
```
terraform apply -auto-approve
```
Wait until terraform finishes updating the instance.

# Connecting to the instance

Use this command to get the generated SSH key and store it with right permissions:
```
terraform output -json playground_ssh_private_key | jq -r . > ~/.ssh/playground_ssh_private.key
chmod 600 ~/.ssh/playground_ssh_private.key
```

Use this command to get the renewed ip address of the instance and remove it from existing hosts, to avoid conflicts when connecting via SSH:
```
export ipAddress=$(cntb get instances --output json | jq -r '.[] | select(.displayName=="MainVPS") | ."ipv4"')
ssh-keygen -R $ipAddress
```

Connect to the instance:
```
ssh -i ~/.ssh/playground_ssh_private.key admin@$ipAddress
```
# Optional: Getting other attributes of the instance
You can also get the root password generated if you want:
```
rootPassword=$(terraform output -json playground_root_password | jq -r .)
echo "$rootPassword"
```
Or you can get the cloud config generated:
```
cloudConfig=$(terraform output -json playground_cloud_config_file | jq -r .)
echo "$cloudConfig"
```
You can always check all the attributes of the instance directly from the Contabo API:
```
instanceDetails=$(cntb get instance $instanceId --output json | jq .[0])
echo $instanceDetails | jq .
```

You can also start or stop the instance via Contabo API:
```
cntb start instance $instanceId
```

# Optional: In case the SSH login is not working:
Sometimes the instance cannot get the right credentials when trying to login via SSH or password after modifying it via terraform.  
In such cases, we can force it to take the stored credentials via Contabo API.  
This is the command to force the instance:
```
cntb resetPassword \
    instance "$(cntb get instances --output json | jq -r '.[] | select(.displayName=="MainVPS") | ."instanceId"')" \
    --sshKeys "$(cntb get secrets --output json | jq -r '.[] | select(.name=="main_ssh_key") | ."secretId"')" \
    --rootPassword "$(cntb get secrets --output json | jq -r '.[] | select(.name=="main_root_password") | ."secretId"')"
```

Try connecting to the instance again:
```
export ipAddress=$(cntb get instances --output json | jq -r '.[] | select(.displayName=="MainVPS") | ."ipv4"')
ssh-keygen -R $ipAddress
ssh -i ~/.ssh/playground_ssh_private.key admin@$ipAddress
```




