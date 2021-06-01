#!/bin/bash

myname=mukund

timestamp=$(date '+%d%m%Y-%H%M%S')

s3_bucket=upgrad-mukund

echo  -e  "\t\t\t\t\e[32m <=======================================================UPDTATING PACKAGES==================================================>\e[0m\t"

sudo apt update -y

echo  -e  "\t\t\t\t\e[32m <=======================================================INSTALLING WEB SERVER===============================================>\e[0m\t"

apt list --installed | grep "apache2"

if [ $? -eq 0 ];then

        echo -e  "\e[32m Already installed\e[0m "
else
        sudo apt-get install apache2 -y
fi

echo  -e  " \t\t\t\t\e[32m <======================================================WEB SERVER RUNNING OR NOT===========================================>\e[0m\t"

ps cax | grep apache2
if [ $? -eq 0 ]; then
	echo -e " \e[32mApache2 is running\e[0m"
else
	sudo systemctl restart apache2
	echo  -e  " \e[31mApache2 service not started\e[0m \e[0m Starting Apache....\e[0m \e[32mApache2 started\e[0m"

fi

echo  -e  " \t\t\t\t\e[32m <======================================================WEB SERVER STATUS=====================================================>\e[0m\t"

sudo systemctl status apache2

echo  -e  " \t\t\t\t\e[32m <======================================================ENABLING APACHE2 SERVICE==============================================>\e[0m\t"

systemctl list-unit-files | grep enabled | grep apache2

if [ $? -eq 0 ];then

	echo "Service is already enabled"
else
	sudo systemctl enable apache2

	echo "Apache2 is enabled"
fi

echo  -e  "\t\t\t\t\e[32m <=======================================================EXPORTING LOGS TO AWS S3 BUCKET=======================================>\e[0m\t"

cd /var/log/apache2

tar -cvf /tmp/$myname-httpd-logs-$timestamp.tar access.log error.log

aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar


echo  -e  " \t\t\t\t\e[32m <======================================================BOOKKEEPING OF ARCHIEVED FILES=======================================>\e[0m\t"


if [ -s /var/www/html/inventory.html ]
then
     echo ""
else
	awk 'BEGIN{printf "\t\t\t\tLog Type\t\t\tDate Created\t\ttype\t\tSize\n"}' >/var/www/html/inventory.html
fi

actualsize=$(du -h /tmp/"${myname}-httpd-logs-${timestamp}.tar" | cut -f 1)
echo -e "\t\t\t\thttpd-logs\t\t\t" $timestamp "\ttar\t\t" $actualsize>> /var/www/html/inventory.html

echo -e "\e[33mBookKeeping is present in /var/www/html/inventory.html\e[0m"

cat /var/www/html/inventory.html

echo  -e  " \t\t\t\t\e[32m <=====================================================SCRIPT SCHEDULED TO RUN EVERYDAY======================================>\e[0m\t"

cat /etc/cron.d/automation
if [ $? -eq 1 ]; then
       	echo -e "\e[31mAutomation crone file  does not exist.\e[0m"
	echo -e "\e[32mCreating Now\e[0m"
	touch /etc/cron.d/automation
	echo -e "\e[32mCreated automation file in /etc/cron.d/\e[0m"
	echo "0 0 * * * root /root/AutomationProject/automation.sh" > /etc/cron.d/automation
else
	echo "0 0 * * * root /root/AutomationProject/automation.sh" > /etc/cron.d/automation
fi
