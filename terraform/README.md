# Run the command

cd 
```
terraform -chdir=./environments/playground init
```

```
terraform -chdir=./environments/playground init --upgrade
```

```
terraform -chdir=./environments/playground plan
```

```
terraform -chdir=./environments/playground apply -auto-approve
```

```
terraform -chdir=./environments/playground output -json playground_ssh_private_key | jq -r . > ./ssh_private.key
```

```
echo $(terraform -chdir=./environments/playground output -json playground_root_password | jq -r .)
```