# setupMysql - Role to install mysql/mariadb on a remote server

## Introduction

This role will:
 - Install the required MySQL packages (apt and pip)
 - Enable the mysql service
 - Perform a MySQL Secure install
    - Remove hostbound root user
    - Remove test database

## Example

```
  - name: Install MySQL
    include_role:
      name: setupMysql
```

## Author

Adam Fordyce