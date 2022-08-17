#!/usr/bin/env bash

# Bash script to deploy NGINX, PHP, and Wordpress onto an Ubuntu instance

# Update these variables
dbserver=ip-172-31-87-95.ec2.internal
logfile=~/dbserver.log

# Variables
app_group_name="ansible"
app_user_name="ansible"
mariadb_root_pw="passrootword"
mariadb_database_name="wordpress"
mariadb_app_user="wordpress"
mariadb_app_pwd="apppass"
site_domain_prefix="pla1"
site_domain_suffix="duckdns.org"

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

# Setup Ubuntu PHP repository
echo "Server Setup - Enable Ubuntu PHP Repository"
sudo add-apt-repository -y ppa:ondrej/php &>> ${logfile}

echo "PHP - Install PHP 8.1 Packages"
# Install dependent packages
for pkg in php8.1-bcmath php8.1-cli php8.1-common php8.1-curl \
  php8.1-fpm php8.1-gd php8.1-igbinary php8.1-imagick \
  php8.1-mbstring php8.1-mysql php8.1-opcache php8.1-redis \
  php8.1-soap php8.1-xml php8.1-xmlrpc php8.1-zip;
do
  sudo apt-get -y install ${pkg} &>> ${logfile}
done

# Configure php options
echo "PHP - Configure application user and group"
phpfpmconf=/etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/^user/user = ${app_user_name}/" $phpfpmconf &>> ${logfile}
sed -i "s/^group/group = ${app_group_name}/" $phpfpmconf &>> ${logfile}
sed -i "s/^listen.user/listen.user = ${app_user_name}/" $phpfpmconf &>> ${logfile}
sed -i "s/^listen.group/listen.group = ${app_group_name}/" $phpfpmconf &>> ${logfile}

echo "PHP - Configure max post and upload filesize to 128MB"
phpini=/etc/php/8.1/fpm/php.ini
sed -i "s/^upload_max_filesize/upload_max_filesize = 128M/" $phpini &>> ${logfile}
sed -i "s/^post_max_size/post_max_size = 128M/" $phpini &>> ${logfile}

# Enable the PHP FPM service
echo "PHP - Enable and Start the php8.1-fpm service"
sudo systemctl enable php8.1-fpm.service &>> ${logfile}

# Start the PHP FPM service
sudo systemctl start php8.1-fpm.service &>> ${logfile}

# NGINX
# Setup Ubuntu PHP repository
echo "NGINX - Enable Ubuntu NGINX Repository"
sudo add-apt-repository -y ppa:ondrej/nginx &>> ${logfile}

echo "NGINX - Enable Ubuntu NGINX Repository"
sudo apt-get -y install nginx &>> ${logfile}

echo "NGINX - Create application directory"
appdir=/var/www/html/wordpress/public_html
sudo mkdir -p ${appdir} &>> ${logfile}
sudo chown ${app_user_name}:${app_group_name} ${appdir} &>> ${logfile}

echo "NGINX - Create configuration file"

nginxconfig=/etc/nginx/sites-available/wordpress.conf
echo <<EOF > $nginxconfig &>> ${logfile}
server {
  listen 80;
  root ${appdir};
  index index.php index.html;
  server_name ${site_domain_prefix}.${site_domain_suffix};
  access_log /var/log/nginx/{{ site_domain_prefix }}.access.log;
  error_log /var/log/nginx/{{ site_domain_prefix }}.error.log;
  location / {
    try_files $uri $uri/ =404;
  }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php-fpm.sock;
  }
  location ~ /\.ht {
    deny all;
  }
  location = /favicon.ico {
    log_not_found off;
    access_log off;
  }
  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }
  location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires max;
    log_not_found off;
  }
}
EOF

echo "NGINX - Enable the Wordpress configuration in NGINX"
nginxconfigenabled=/etc/nginx/sites-enabled/wordpress.conf
sudo ln -snf $nginxconfig $nginxconfigenabled &>> ${logfile}

echo "NGINX - Set the Application user"
sudo sed -i "s/^user/user ${app_user_name};/" /etc/nginx/nginx.conf ${logfile}

echo "NGINX - Enable and start the NGINX service"
sudo systemctl enable nginx.service &>> ${logfile}
sudo systemctl start nginx.service &>> ${logfile}

# Wordpress
echo "Wordpress - Install MariaDB Client"
sudo apt-get -y install mariadb-client &>> ${logfile}

echo "Wordpress - Create temporary directory"
tmpdir=/tmp/wpinstall
mkdir -p ${tmpdir} &>> ${logfile}

echo "Wordpress - Download the WP-CLI"
sudo curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --output /usr/local/bin/wp &>> ${logfile}
sudo chmod 0777 /usr/local/bin/wp &>> ${logfile}

echo "Wordpress - Download the WP-CLI Bash completion"
sudo curl https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash --output /etc/bash_completion.d/wp-completion.bash &>> ${logfile}
sudo chmod 0777 /etc/bash_completion.d/wp-completion.bash &>> ${logfile}

echo "Wordpress - Download the latest version of Wordpress"
sudo curl https://wordpress.org/latest.tar.gz --output ${tmpdir}/latest.tar.gz &>> ${logfile}
sudo chmod 0777 ${tmpdir}/latest.tar.gz &>> ${logfile}
sudo chown ${app_user_name}:${app_group_name} ${tmpdir}/latest.tar.gz &>> ${logfile}

echo "Wordpress - Unpack wordpress into the application directory"
sudo mkdir -p ${tmpdir}/wp
sudo tar xvf ${tmpdir}/latest.tar.gz -C ${tmpdir}/wp/ &>> ${logfile}
sudo mv ${tmpdir}/wp/wordpress * ${appdir}/ &>> ${logfile}
sudo chmod 0744 ${appdir} &>> ${logfile}
sudo chown -R ${app_user_name}:${app_group_name} ${appdir} &>> ${logfile}

echo "Wordpress - Configure wp-config.php"
echo <<EOF > $appdir/wp-config.php &>> ${logfile}
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', '${mariadb_database_name}' );

/** MySQL database username */
define( 'DB_USER', '${mariadb_app_user}' );

/** MySQL database password */
define( 'DB_PASSWORD', '${mariadb_app_pwd}' );

/** MySQL hostname */
define( 'DB_HOST', '${dbhost}' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/** Filesystem access **/
define('FS_METHOD', 'direct');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'SECURE_AUTH_KEY',  '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'LOGGED_IN_KEY',    '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'NONCE_KEY',        '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'AUTH_SALT',        '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'SECURE_AUTH_SALT', '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'LOGGED_IN_SALT',   '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );
define( 'NONCE_SALT',       '{{ lookup('password', '/dev/null chars=ascii_letters length=64') }}' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
EOF

echo "Wordpress - Remove temporary directory"
sudo rm -rf ${tmpdir} &>> ${logfile}

echo "Wordpress - Restart PHP-FPM"
sudo systemctl restart php8.1-fpm.service &>> ${logfile}

echo "Wordpress - Restart NGINX"
sudo systemctl restart nginx.service &>> ${logfile}

# TODO Install Wordpress using wp-cli

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

#sudo ufw allow 3306
# HTTP
echo "Firewall - Allow Port 80 and 443 on the firewall"
sudo ufw allow 80 &>> ${logfile}
sudo ufw allow 443 &>> ${logfile}