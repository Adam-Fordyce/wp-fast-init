# setup_php: - Role to install PHP on a remote server

## Introduction

This role will:
 - Install the required PHP packages
 - Enable the php-fpm service on startup

## Example

```
  - name: Install PHP
    include_role:
      name: setup_php:
```

## Author

Adam Fordyce
