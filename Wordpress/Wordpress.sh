#!/bin/bash
LOG=wordpress.log
ERROR=wordpress.err
#Function to restart php-fpm
php_restart(){
    service php7.1-fpm start
    service php7.1-fpm reload
    service php7.1-fpm restart
}
#Configuration Function
configure(){
    echo -e "\n Starting Configuring \n"
    domain=$1
    #Domain Config for nginx
    domain_conf="$domain".conf
    dbname="$domain"_db
    #Performing SED operation for configuration
    service nginx start
    echo "Starting Mysql Server"
    service mysql start
    #Copying Default nginx config file to a temp file
    cp /etc/nginx/sites-available/default $PWD/default.backup
    echo "Configuration Operations"
    sed -f sedscript default.backup > $PWD/default
    mv $PWD/default /etc/nginx/sites-available/default
    php_restart
    service nginx restart
    nginx -t
    #Checking if there is already an entry for Example.com in etc/hosts
    if cat /etc/hosts | grep "127.0.0.1 example.com www.example.com"
    then
        echo "Configuration Already made in /etc/hosts"
    else
        #Making an entry in /etc/hosts for Example.com
        echo '127.0.0.1 '"$domain www.$domain" >> /etc/hosts
    fi
    #Editing Default for Example.com configuration same as did in Default Config file 
    sed -i 's/\/var\/www\/html/\/var\/www\/'$domain'\/html/' /etc/nginx/sites-available/default
    sed -i 's/server_name _/server_name '$domain_name' www.'$domain_name'/' /etc/nginx/sites-available/default
    sed -i 's/ default_server//' /etc/nginx/sites-available/default
    cat /etc/nginx/sites-available/default > /etc/nginx/sites-available/$domain_conf
    #Moving Example.com.conf file back to /etc/nginx/sites-available/
    #mv $PWD/$domain_conf /etc/nginx/sites-available/$domain_conf
    #Creating Link for Example.com.conf in etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/$domain_conf /etc/nginx/sites-enabled/$domain_conf
    #Removing Default Config file
    rm /etc/nginx/sites-available/default
    rm /etc/nginx/sites-enabled/default
    #Making Directories for Example.com Location
    mkdir -p /var/www/$domain/html
    #Creating database for Wordpress
    echo -e "Creating DataBase with name : $dbname\n"
    if mysql -uroot -p$db_password -e 'CREATE DATABASE `'$dbname'`;'
    then
        echo "Database Created with : $dbname name"
    else
        echo "Unable to create Database"
    fi
    #Reading user password to set for that specific database
    re=0
    while [ $re -eq 0 ]
    do
        read -sp "Enter Password for Wordpress Database : " wordpress_password
        echo
        read -sp "Re-Enter Password for Wordpress Database : " wordpress_re_password
        if [ $wordpress_password == $wordpress_re_password ]
        then
            echo -e "\nPassword for $dbname will be set as entered above"
            re=1
        else
            echo -e "\nEntered password do not match"
        fi
    done
    #Granting Privileges to that specific (wordpress) user on that database
    if mysql -uroot -p$db_password -e 'GRANT ALL ON `'$dbname'`.* TO "wordpress"@"localhost" IDENTIFIED BY "'$wordpress_password'";'
    then
        mysql -uroot -p$db_password -e 'FLUSH PRIVILEGES;'
        echo -e "\nGranted Privileges\n"
    else
        echo "Problem in granting privileges\n"
    fi
    #Downloading Latest Wordpress
    echo -e "Downloading Wordpress\n"
    cd /tmp/
    wget "https://wordpress.org/latest.tar.gz"
    echo -e "Extracting files\n"
    #Extracting wordpress in /tmp/
    tar xzvf latest.tar.gz
    echo "Hold on !! Almost Done\n"
    #Now, To configure Wordpress, Copying sample config file into wp-config.php
    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
    #Copying all the content to our location
    cp -a /tmp/wordpress/. /var/www/example.com/html/
    #Setting Permissions and Ownership
    chown -R $USER:www-data /var/www/example.com/html
    find /var/www/example.com/html -type d -exec chmod g+s {} \;
    chmod g+w /var/www/example.com/html/wp-content
    chmod -R g+w /var/www/example.com/html/wp-content/themes
    chmod -R g+w /var/www/example.com/html/wp-content/plugins
    #Setting SALT for Authentications
    echo "Setting Up SALT"
    cd /var/www/example.com/html/
    #Downloading SALT
    wget https://api.wordpress.org/secret-key/1.1/salt/ -O salt.txt
    #Editing into wp-config.php file to setup SALT and DB connection Credentials
    sed -i '49,56d;57r salt.txt' wp-config.php
    sed -i 's/database_name_here/'$dbname'/' wp-config.php
    sed -i 's/username_here/wordpress/' wp-config.php
    sed -i 's/password_here/'$wordpress_password'/' wp-config.php
    #Restarting All the services
    php_restart
    service nginx reload
    service nginx restart
    nginx -t
    echo -e "\n\n--------DONE--------\n\n"
}
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
re=0
#Entering Root password for database if installed enter password or else set a password
while [ $re -eq 0 ]
do
    read -sp "Enter your MYSQL password : " db_password
    echo
    read -sp "Re-Enter your MYSQL password : " re_db_password
    if [ $db_password == $re_db_password ]
    then
        echo -e "\nPassword will be set for the DB Root"
        re=1
    else
        echo -e "\nPassword Did not match"
    fi
done
#Enter Domain name for setup
echo
read -p "Enter your Domain Name : " domain_name
echo "---------------CHECKING--------------";
#Array of Items to install
array_name=(wget curl nginx php7.1-fpm php7.1-mysql mysql-server mysql-client php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc);
uninstalled=()
counter=0
check(){
    counter=0
    for i in "${array_name[@]}";
    do
        #Checking if the package is installed
        echo -e "Checking for $i > > > >\n";
        dpkg -s $i &> /dev/null
        if [ $? -eq 0 ];
        then
            echo -e "${GREEN}> > > > $i IS Installed${NC}\n"
        else
            echo -e "${RED}! ! > > > >$i is NOT Installed${NC}\n"
            #Adding packages into array that is needed to be installed
            uninstalled+=($i);
            #counter
            counter=`expr $counter + 1`;
        fi
    done
}
check
echo "------------END CHECKING-------------";
#Array of uninstalled packages
echo "Uninstalled Packages :" ${uninstalled[@]}
#Count of uninstalled Packages , if 0 will not continue further and will move to configure
if [ $counter -gt 0 ];
then
    #Taking User Choice of Installation
    read -p 'Would you like to install them manually or through script (y/n) : ' choice
    if [ $choice == 'y' ];
    then
        echo "Auto-Install"
        #Checking For Superuser
        if [ $UID -ne 0 ];
        then
            echo "You are not a root user"
        else
            #Installing Updates
            if apt-get update >>$LOG 2>>$ERROR
            then
                echo "Updated"
            else
                echo "Something went Wrong While updating!"
            fi
            #For Each of the Uninstalled Package , Perform the installation
            for i in "${uninstalled[@]}";
            do
                #If mysql-server is needed to be installed , Setting password for Root user of Mysql
                if [ $i == 'mysql-server' ]
                then
                    debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$db_password''
                    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$db_password''
                fi
                #Finally Installing the package one by one
                echo "Installing $i";
                echo "--------------------------------"
                echo -e "${GREEN} > > > INSTALLING $i.${NC}" >> install.log
                if apt-get install $i -y >>$LOG 2>>$ERROR
                then
                    echo -e "${GREEN}Successfully installed $i.${NC}"
                    echo "---------------------------------"
                else
                    echo -e "${RED}Error during installation of $i.${NC}"
                fi
            done
            #Checking again for the uninstalled packages
            check
            if [ $counter -gt 0 ]
            then
                #If some packages are uninstalled due to some problems, not configure , exit
                echo "Some Packages Are Still Uninstalled :" ${uninstalled[@]}
                exit 1
            else
                #If all the packages installed , Configure
                echo "All packages are Installed Correctly"
                configure $domain_name | tee -a configure.log
            fi
        fi
    else
        #If user wants to manually Setup or choose not to install by script
        echo "Manual Install and Manual Configure/or Run Script for Configuration after all the LEMP installation"
    fi
else
    #No packages are to install, Configure
    echo -e "\nNo packages to install"
    configure $domain_name | tee -a configure.log
fi
