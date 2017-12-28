#!/bin/bash
configure(){
    domain=$1
    domain_conf="$domain".conf
    dbname="$domain"_db
    #Performing SED operation for configuration
    echo "Wait 10sec"
    sleep 10
    if [ -f /etc/nginx/sites-available/default ];
    then
        echo "Default Config File present"
        service nginx reload
        service nginx start
        service nginx restart
    else
        echo "Default Config File not Present"
    fi
    echo "Starting Mysql Server"
    service mysql start
    echo "Wait 10sec"
    sleep 10
    cp /etc/nginx/sites-available/default $PWD/.default_temp
    echo "SED Operations"
    sed -f sedscript .default_temp > default
    mv $PWD/default /etc/nginx/sites-available/default
    service php7.1-fpm reload
    service php7.1-fpm start
    service nginx reload
    service nginx restart
    nginx -t
    echo "Creating Virtual Server Block for $domain"
    echo '127.0.0.1 '"$domain www.$domain" >> /etc/hosts
    cp /etc/nginx/sites-available/default $PWD/.example_temp.com
    sed 's/\/var\/www\/html/\/var\/www\/'$domain'\/html/' .example_temp.com > $PWD/.example.com
    sed 's/server_name _/server_name '$domain_name' www.'$domain_name'/' $PWD/.example.com > $PWD/.example_temp.com
    sed 's/ default_server//' $PWD/.example_temp.com > $PWD/$domain_conf
    mv $PWD/$domain_conf /etc/nginx/sites-available/$domain_conf
    ln -s /etc/nginx/sites-available/$domain_conf /etc/nginx/sites-enabled/$domain_conf
    rm /etc/nginx/sites-available/default
    rm /etc/nginx/sites-enabled/default
    mkdir -p /var/www/$domain/html
    echo -e "Creating DataBase with name : $dbname\n"
    if mysql -uroot -p$db_password -e 'CREATE DATABASE `'$dbname'`;'
    then
        echo "Database Created with : $dbname name"
    else
        echo "Unable to create Database"
    fi
    read -sp "Enter Password for Wordpress Database : " wordpress_password
    if mysql -uroot -p$db_password -e 'GRANT ALL ON `'$dbname'`.* TO "wordpress"@"localhost" IDENTIFIED BY "'$wordpress_password'";'
    then
        mysql -uroot -p$db_password -e 'FLUSH PRIVILEGES;'
        echo -e "Granted Privileges\n"
    else
        echo "Problem in granting privileges"
    fi
    echo -e "Downloading Wordpress"
    cd /tmp/
    wget "https://wordpress.org/latest.tar.gz"
    echo -e "Extracting files"
    tar xzvf latest.tar.gz
    echo "Hold on !! Almost Done\n"
    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
    mkdir /tmp/wordpress/wp-content/upgrade
    cp -a /tmp/wordpress/. /var/www/example.com/html/
    chown -R $USER:www-data /var/www/example.com/html
    find /var/www/example.com/html -type d -exec chmod g+s {} \;
    chmod g+w /var/www/example.com/html/wp-content
    chmod -R g+w /var/www/example.com/html/wp-content/themes
    chmod -R g+w /var/www/example.com/html/wp-content/plugins
    echo "Setting Up SALT"
    cd /var/www/example.com/html/
    wget https://api.wordpress.org/secret-key/1.1/salt/ -O salt.txt
    sed -i '49,56d;57r salt.txt' wp-config.php
    sed -i 's/database_name_here/'$dbname'/' wp-config.php
    sed -i 's/username_here/wordpress/' wp-config.php
    sed -i 's/password_here/'$wordpress_password'/' wp-config.php
    service php7.1-fpm reload
    service php7.1-fpm restart
    service nginx reload
    service nginx restart
    nginx -t
    echo -e "\n\n--------DONE--------\n\n"
}
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
re=0
while [ $re -eq 0 ]
do
    read -sp "Enter your MYSQL password : " db_password
    read -sp "\nRe-Enter your MYSQL password : " re_db_password
    if [ $db_password == $re_db_password ]
    then
        echo -e "\nPassword will be set for the DB Root"
        re=1
    else
        echo -e "\nPassword Did not match"
    fi
done
read -p "\nEnter your Domain Name : " domain_name
echo "---------------CHECKING--------------";
array_name=( nginx php7.1-fpm php7.1-mysql mysql-server mysql-client php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc);
uninstalled=()
counter=0
for i in "${array_name[@]}";
do
    echo -e "Checking for $i > > > >\n";
    dpkg -s $i &> /dev/null
    if [ $? -eq 0 ];
    then
        echo -e "${GREEN}> > > > $i IS Installed${NC}\n"
    else
        echo -e "${RED}! ! > > > >$i is NOT Installed${NC}\n"
        uninstalled+=($i);
        counter=`expr $counter + 1`;
    fi
done
echo "------------END CHECKING-------------";
echo "Uninstalled Packages :" ${uninstalled[@]}
if [ $counter -gt 0 ];
then
    read -p 'Would you like to install them manually or through script (y/n) : ' choice
    if [ $choice == 'y' ];
    then
        echo "Auto-Install"
        if [ $UID -ne 0 ];
        then
            echo "You are not a root user"
        else
            if apt-get update | tee -a install.log
            then
                echo "Updated"
            else
                echo "Something went Wrong While updating!"
            fi
            for i in "${uninstalled[@]}";
            do
                if [ $i == 'mysql-server' ]
                then
                    debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$db_password''
                    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$db_password''
                    ms_flag=1
                    echo "Mysql-Server Flag set"
                else
                    ms_flag=0
                fi
                if [ $i == 'php7.1-fpm' ]
                then
                    fpm_flag=1
                    echo "PHP-FPM flag set"
                else
                    fpm_flag=0
                fi
                if [ $i == 'nginx' ]
                then
                    nginx_flag=1
                    echo "Nginx flag set"
                else
                    nginx_flag=0
                fi
                echo "Installing $i";
                echo "--------------------------------"
                echo -e "${GREEN} > > > INSTALLING $i.${NC}" >> install.log
                if apt-get install $i -y | tee -a install.log;
                then
                    echo -e "${GREEN}Successfully installed $i.${NC}"
                    echo "---------------------------------"
                else
                    echo -e "${RED}Error during installation of $i.${NC}"
                fi
            done
            configure $domain_name
        fi
    else
        echo "Manual Install and Manual Configure/or Run Script for Configuration after all the LEMP installation"
    fi
else
    echo "No packages to install\n"
    echo "Configuring the Sever"
    configure $domain_name
fi
#TO-DO
#Check for db_password auto set correction
#Check for Deletion and then empty etc/nginx/sites-available/default correction
#Put Sed operations in Function and Restart too , check presence of everything and check for already installed as well(during restart and check)
#call(SED and service function) if all the packages are already installed and also when not install then call after installation
#download Wordpress and make sure to download .tar.gz file
#extract it in example.com/html in root (/var/www/example.com/html/)
#Create database with name "$domain_name_db"
#create "wp-config.php" file and put in ever required data
#set PRIVILEGES or your own safety
#Clean everything and write README.md
#write small help me function make necessary changes
#recheck to make everything automated
#Clean all temp files and code cleaning
#make comments
#Finally test it on your AWS
#Make changes if necessary
#GIT PUSH

