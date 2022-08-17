#!/usr/bin/env bash

# Bash script to deploy MySQL onto an Ubuntu instance

# Update these variables
webserver=ip-172-31-87-95.ec2.internal
logfile=~/test.log

# Variables
app_group_name=ansible
app_user_name=ansible
mariadb_root_pw="passrootword"
mariadb_database_name=wordpress1
mariadb_app_user=wordpress1
mariadb_app_pwd="apppass"

echo "Variables"
echo -e "\twebserver=${webserver}"
echo -e "\tlogfile=${logfile}"
echo -e "\tapp_group_name=${app_group_name}"
echo -e "\tapp_user_name=${app_user_name}"
echo "Variables that should be secured"
echo -e "\tmariadb_root_pw=${mariadb_root_pw}"
echo -e "\tmariadb_database_name=${mariadb_database_name}"
echo -e "\tmariadb_app_user=${mariadb_app_user}"
echo -e "\tmariadb_app_pwd=${mariadb_app_pwd}"

# Setup user account
echo "Server Setup - Creating user ${app_user_name} in group ${app_group_name}"
sudo groupadd ${app_group_name} &>> ${logfile}
sudo useradd -m -N -s /bin/bash ${app_user_name} -G ${app_group_name} &>> ${logfile}

# Setup ubuntu universe repository
echo "Server Setup - Enable Ubuntu universe repository"
sudo add-apt-repository -y universe &>> ${logfile}

# Update the OS
echo "Server Setup - Update the OS"
sudo apt-get -y update &>> ${logfile}

# Upgrade the OS
echo "Server Setup - Upgrade the OS" &>> ${logfile}
#sudo apt-get -y dist-upgread

# Database:
# Ref: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04

# Install dependent packages
for pkg in python3-dev python3-pip libmysqlclient-dev mysqlclient mariadb-server;
do
  sudo apt-get -y install ${pkg} &>> ${logfile}
done

# Configure mariadb options
echo "MySQL - Configure MySQL to listen on all IPV4 interfaces"
findstr="^bind-address            = 127.0.0.1"
replacestr="bind-address            = 0.0.0.0"
config=/etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i "s/${findstr}/${replacestr}/" ${config} &>> ${logfile}

# Enable the mariadb service
echo "MySQL - Enable and Start the mariadb service"
sudo systemctl enable mariadb.service &>> ${logfile}

# Start the mariadb service
sudo systemctl start mariadb.service &>> ${logfile}

# Secure MySQL installation
# Ref: https://lowendbox.com/blog/automating-mysql_secure_installation-in-mariadb-setup/
echo "MySQL - Secure database"
mysql -sfu root <<EOS &>> ${logfile}
-- set root password
UPDATE mysql.user SET Password=PASSWORD('$mariadb_root_pw') WHERE User='root';
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS

# Create application database and user
echo "MySQL - Create application database ${mariadb_database_name}"
mysql -sfu root -p${mariadb_root_pw} -e "CREATE DATABASE IF NOT EXISTS ${mariadb_database_name}" &>> ${logfile}
echo "MySQL - Create application database user ${mariadb_app_user}"
mysql -sfu root -p${mariadb_root_pw} -e "CREATE USER IF NOT EXISTS '${mariadb_app_user}'@'localhost' IDENTIFIED BY '${mariadb_app_pwd}';" &>> ${logfile}
echo "MySQL - Allow application database connections from localhost and ${webserver}"
mysql -sfu root -p${mariadb_root_pw} -e "GRANT ALL PRIVILEGES ON ${mariadb_database_name}.* TO '${mariadb_app_user}'@'localhost';" &>> ${logfile}
mysql -sfu root -p${mariadb_root_pw} -e "GRANT ALL PRIVILEGES ON ${mariadb_database_name}.* TO '${mariadb_app_user}'@'${webserver}';" &>> ${logfile}
mysql -sfu root -p${mariadb_root_pw} -e "FLUSH PRIVILEGES;" &>> ${logfile}

# Ref: https://www.linode.com/docs/guides/configure-firewall-with-ufw/
# Start the firewall
echo "Firewall - Install/Enable/Start"
sudo apt-get -y install ufw &>> ${logfile}
sudo systemctl enable ufw.service &>> ${logfile}
sudo systemctl start ufw.service &>> ${logfile}

# Set the default rules
echo "Firewall - Set all egress data to be allowed"
sudo ufw default allow outgoing &>> ${logfile}
echo "Firewall - Set all ingress data to be denied"
sudo ufw default deny incoming &>> ${logfile}

# SSH
echo "Firewall - Allow Port 22"
sudo ufw allow 22 &>> ${logfile}
# MySQL
echo "Firewall - Allow Port 3306 from ${webserver}"
sudo ufw allow proto tcp from ${webserver} to any port 3306 &>> ${logfile}
#sudo ufw allow 3306
# HTTP
echo "Firewall - Allow Port 80 and 443 on the firewall"
sudo ufw allow 80 &>> ${logfile}
sudo ufw allow 443 &>> ${logfile}