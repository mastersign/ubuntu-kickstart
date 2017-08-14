# Add Webmin Package Repo
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Update packages
apt-get update >> $user_home/apt-upgrade.log
apt-get dist-upgrade -y >> $user_home/apt-upgrade.log

# Install Webmin
apt-get install webmin -y > $user_home/webmin-install.log

