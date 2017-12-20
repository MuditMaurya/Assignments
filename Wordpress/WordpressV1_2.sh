#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo "---------------CHECKING--------------";
array_name=( php7.0 mysql-server mysql-client nginx );
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
    echo "Would you like to install them manually or through script"
    read choice
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
                echo "Installing $i";
                echo "INSTALLING $i" >> install.log
                if apt-get install $i | tee -a install.log;
                then
                    echo "Successfully installed $i"
                else
                    echo "Error during installation of $i"
                fi
            done
        fi
    else
        echo "Manual Install"
    fi
else
    echo " No packages to install "
fi
