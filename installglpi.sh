
#------------------------------------------------
#  INSTALACAO DO GLPI NA ULTIMA VERSAO ESTAVEL NO UBUNTU 22.04
#
#   DOWNLOAD: https://mirror.pop-sc.rnp.br/ubuntu-releases/22.04.2/ubuntu-22.04.2-live-server-amd64.iso
#------------------------------------------------
#
#
echo "#------------------------------------------#"
echo           "INSTALANDO APACHE" 
echo "#------------------------------------------#"
#
export apt install -y apache2 && a2enmod rewrite
#
clear
echo "#------------------------------------------#"
echo           "HABILITANDO PHP 8.1" 
echo "#------------------------------------------#"
#
apt install -y apt-transport-https lsb-release software-properties-common ca-certificates
echo | add-apt-repository ppa:ondrej/php
apt install php8.1 -y  
#
clear
echo "#------------------------------------------#"
echo           "INSTALANDO DEPENDENCIAS" 
echo "#------------------------------------------#"
#
apt -y install php8.1 php8.1-soap php8.1-apcu php8.1-cli php8.1-common php8.1-curl php8.1-gd php8.1-imap php8.1-ldap php8.1-mysql php8.1-snmp php8.1-xmlrpc php8.1-xml php8.1-intl php8.1-zip php8.1-bz2 php8.1-mbstring php8.1-bcmath 
apt -y install php8.1-fpm && systemctl enable php8.1-fpm
apt -y install bzip2 curl mycli wget ntp libarchive-tools
apt -y install mysql-server
service apache2 restart
service php8.1-fpm restart
#
clear
echo "#------------------------------------------#"
echo  "BAIXANDO GLPI 10.0.14" 
echo "#------------------------------------------#"
#
sudo wget https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz
#Descompactar GLPI
echo "Descompactar GLPI "
sudo tar xvf glpi-10.0.14.tgz
sudo mv glpi /var/www/html


#
clear
echo "#------------------------------------------#"
echo    "CRIANDO DIRETORIOS E DANDO PERMISSAO" 
echo "#------------------------------------------#"
#
sudo chown -R apache:apache /var/www/html/glpi
sudo chmod -R 755 /var/www/html/glpi
clear

# Criação do banco de dados e usuário para o GLPI
echo "Criando o banco de dados e usuário para o GLPI..."
sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'Spl@Engine#db';
GRANT ALL ON glpi.* TO 'glpi'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO DOWNSTREAM" 
echo "#------------------------------------------#"
#
sudo a2dissite 000-default

#
clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO APACHE-VHOST" 
echo "#------------------------------------------#"
#
touch /etc/apache2/conf-available/glpi.conf
cat <<EOF | tee /etc/apache2/conf-available/glpi.conf
Alias /glpi /var/www/html/glpi/public

# Redirect configuration for multi-glpicanalteste install_oriation
# You can set this value in each vhost configuration
# SetEnv glpicanalteste_CONFIG_DIR /etc/glpi

<Directory /var/www/html/glpi/public>
    Require all granted

    RewriteEngine On

    # Redirect all requests to GLPI router, unless file exists.
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
    
</Directory>

#<Directory /var/www/html/glpi/
#    Options None
#    AllowOverride Limit Options FileInfo
#
#    <IfModule mod_authz_core.c>
#        Require all granted
#    </IfModule>
#    <IfModule !mod_authz_core.c>
#        Order deny,allow
#        Allow from all
#    </IfModule>
#</Directory>

<Directory /var/www/html/glpi/install_ori>

    # Install is only allowed via local access (from the GLPI server).
    # Add your IP address if you need it for remote installation,
    # but remember to remove it after installation for security.

    <IfModule mod_authz_core.c>
        # Apache 2.4
#        Require local
        # Require ip ##.##.##.##
    </IfModule>
    <IfModule !mod_authz_core.c>
        # Apache 2.2
        Order Deny,Allow
#        Deny from All
        Allow from 127.0.0.1
        Allow from ::1
    </IfModule>

    ErrorDocument 403 "<p><b>Restricted area.</b><br />Only local access allowed.<br />Check your configuration or contact your administrator.</p>"

    <IfModule mod_php5.c>
        # migration could be very long
        php_value max_execution_time 0
        php_value memory_limit -1
    </IfModule>
    <IfModule mod_php7.c>
        # migration could be very long
        php_value max_execution_time 0
        php_value memory_limit -1
    </IfModule>
</Directory>

<Directory /var/www/html/glpi/config>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /var/www/html/glpi/locales>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /var/www/html/glpi/install/mysql>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /var/www/html/glpi/scripts>
    Order Allow,Deny
    Deny from all
</Directory>

# some people prefer a simple URL like http://glpi.example.com

<VirtualHost *:80>

  DocumentRoot /var/www/html/glpi
  ServerName glpi.asf-local.com
  ServerAlias www.glpi.asf-local.com
  ServerAdmin glpi@asf-local.com

</VirtualHost>
EOF
service apache2 restart
a2enconf glpi.conf
systemctl reload apache2
#
clear
echo "#-----------------------------------------#"
echo               "AJUSTE PHP.INI"
echo "#-----------------------------------------#"
#
sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/8.1/apache2/php.ini
sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.1/apache2/php.ini
sed -i 's/^memory_limit = 128M/memory_limit = 512M/' /etc/php/8.1/apache2/php.ini
sed -i 's/;*session.cookie_httponly =.*/session.cookie_httponly = on/' /etc/php/8.1/apache2/php.ini
systemctl restart apache2
service php8.1-fpm restart
systemctl enable apache2
#
clear
# echo "#-----------------------------------------#"
# echo          "CRIANDO BASE DE TESTE"
# echo "#-----------------------------------------#"
# #
# cp -Rfp /var/www/html/glpi /usr/share/teste
# cp -Rfp /etc/glpi /etc/teste
# cp -Rfp /var/lib/glpi /var/lib/teste
# cp -Rfp /var/log/glpi /var/log/teste
# cp -Rfp /etc/apache2/conf-available/glpi.conf /etc/apache2/conf-available/teste.conf
# rm -Rf /etc/teste/config_db.php
# sed -i 's/glpi/teste/' /etc/apache2/conf-available/teste.conf
# sed -i 's/glpi/teste/' /etc/apache2/conf-available/teste.conf
# sed -i 's/glpi/teste/' /usr/share/teste/inc/downstream.php
# chown www-data:www-data -Rf /usr/share/teste/marketplace
# a2enconf teste.conf
systemctl reload apache2
systemctl restart apache2
#
clear
# echo "#-----------------------------------------#"
# echo     "INSTALE O SGDB DA SUA PREFERENCIA"
echo "#-----------------------------------------#"
echo "ACESSE O GLPI PELO NAVEGADOR E CONCLUA A INSTALACAO"
echo "#-----------------------------------------#" 
# echo "RODE O COMANDO ABAIXO APOS CONCLUIR A INSTALACAO PELO NAVEGADOR"
# echo "mv /var/www/html/glpi/install/ /var/www/html/glpi/install_old"
# echo "mv /usr/share/teste/install/ /usr/share/teste/install_old"
# echo "#-----------------------------------------#"
# echo "DESCOMENTE A LINHA 33 E 39 DO ARQUIVO /etc/apache2/conf-available/glpi.conf E REINICIE O APACHE"
# echo "DESCOMENTE A LINHA 33 E 39 DO ARQUIVO /etc/apache2/conf-available/teste.conf E REINICIE O APACHE"
echo "#-----------------------------------------#"
echo "ALTERE A SENHA E REMOVA OS 3 "USUARIOS" ABAIXO"
echo "normal"
echo "post-only"
echo "tech"
echo "#-----------------------------------------#"
echo                  "FIM"
echo "#-----------------------------------------#"


