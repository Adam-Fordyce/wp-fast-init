# wp-fast-init

## Introduction

This project intends to install and configure the required applications onto a fresh ubuntu 18.04 / 20.04 cloud server.

> This project is a work-in-progress and in a development state at the moment
## Setup

### Launch a cloud server

Example, an Any Cloud Guru sandbox instance on Azure/AWS/GCP would suffice.

### Create the Ansible Vault

Create a new file: `inventory/group_vars/all/vault`
Set the required parameters for an existing cloud server:
 - IP address
 - Domain name
 - Username
 - SSH Keyfile data
 - MySQL root user details
 - Wordpress user details

```yaml
---
# Vault data for wp-fast-init project
remote_ip_address: {IP ADDRESS OF CLOUD SERVER}
ssh_user_name: {USERNAME OF REMOTE INSTANCE}
ssh_key_data: |
    ---- PASTE SSH PRIVATE KEY DATA HERE ----

ssh_pub_key_data: |
    ---- PASTE SSH PUBLIC KEY DATA HERE ----

primary_domain: {example.co.uk}
alternate_domain: {www.example.co.uk}

mysql_root_password: {Database Super User password}
mysql_wordpress_database: {Name of Database}
mysql_wordpress_username: {Wordpress MySql username}
mysql_wordpress_password: {Wordpress MySql password}
...
```

#### Create an Ansible Vault password

Create a strong password to be used for encrypting and decrypting the secrets that will be stored in the ansible vault.

```bash
echo "MyStR0ngP@$sW0rdI5gr34t!" > passwd
```

> The passwd file is omitted from git commits as it is defined inside the `.gitignore` file.

#### Encrypt the Ansible Vault

To encypt the ansible vault file once it has been populated use the following command.

```bash
ansible-vault encrypt inventory/group_vars/all/vault --vault-id passwd
```

## Execute the playbook and configure the Wordpress application

```
ansible-playbook -i inventory provision.yml --vault-id passwd
```

## Author

Adam Fordyce
