# wp-fast-init

## Introduction

This project intends to install and configure the required applications onto a fresh ubuntu 18.04 / 20.04 cloud server. 

> This project is a work-in-progress and in a development state at the moment
## Setup

Update the inventory and set the required parameters for an existing cloud server:
 - IP address
 - Domain name
 - Username
 - SSH Keyfile data
 - MySQL root user details
 - Wordpress user details

## Example

ansible-playbook -i inventory plays/provision.yml
## Author

Adam Fordyce