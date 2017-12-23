#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
re=0
while [ re = 0 ]
do
    read -sp 'Enter your DB password : ' db_password
    read -sp 'Re-Enter your DB password : ' re_db_password
    if [ $db_password == $re_db_password ]
    then
        echo "Password will be set for the DB Root"
        re=1
    else
        echo "Password Did not match"
    fi
done
read -p "Enter your Domain Name : "domain_name
echo "---------------CHECKING--------------";
array_name=( nginx php7.1-fpm php7.1-mysql mysql-server mysql-client );
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
            #Performing SED operation for configuration
            cp /etc/nginx/sites-available/default PWD 
            sed -f sedscript default 
            mv PWD/default /etc/nginx/sites-available/default
            service php7.1-fpm start
            service php7.1-fpm reload
            service php7.1-fpm restart
            service nginx reload
            service nginx restart
            #Start all services
            #Reload all services
            #Restart all service
        fi
    else
        echo "Manual Install"
    fi
else
    echo " No packages to install "
fi
#TO-DO
#Check for db_password auto set correction
#Check for Deletion and then empty etc/nginx/sites-available/default correction
