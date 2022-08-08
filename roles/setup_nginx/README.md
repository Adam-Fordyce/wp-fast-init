# setup_nginx: - Role to install nginx on a remote server

## Introduction

This role will:
 - Install the NginX package
 - Enable the nginx service on startup
 - Configure the nginx service to start
 - Create the application path that is to be served
 - Create the WordPress specific nginx configuration file
 - Create a symbolic link to the configuration to enable the site
 - Reload the service

## Example

```
  - name: Install NginX
    include_role:
      name: setup_nginx:
```

## Author

Adam Fordyce
