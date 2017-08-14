# Configure sSMTP

ssmtp_mailhub=$(cfgval 'ssmtp_mailhub')
ssmtp_auth_user=$(cfgval 'ssmtp_auth_user')
ssmtp_auth_pass=$(cfgval 'ssmtp_auth_pass')
ssmtp_use_startssl=$(cfgval 'ssmtp_use_startssl')
ssmtp_from_line_override=$(cfgval 'ssmtp_from_line_override')
ssmtp_from_address=$(cfgval 'ssmtp_from_address')

echo "Writing /etc/ssmtp/ssmtp.conf" >> $user_home/ssmtp-install.log
echo "root=postmaster
hostname=$host_name
mailhub=$ssmtp_mailhub
AuthUser=$ssmtp_auth_user
AuthPass=$ssmtp_auth_pass
UseSTARTSSL=$ssmtp_use_startssl
FromLineOverride=$ssmtp_from_line_override" > /etc/ssmtp/ssmtp.conf
echo "
root:$ssmtp_from_address:$ssmtp_mailhub
$user_name:$ssmtp_from_address:$ssmtp_mailhub" >> /etc/ssmtp/revaliases
echo "Creating group mailing" >> $user_home/ssmtp-install.log
groupadd mailing >> $user_home/ssmtp-install.log
echo "Adapting access rights for /etc/ssmtp/ssmtp.conf" >> $user_home/ssmtp-install.log
chmod 640 /etc/ssmtp/ssmtp.conf
chmod 640 /etc/ssmtp/revaliases
chown root:mailing /etc/ssmtp/ssmtp.conf
chown root:mailing /etc/ssmtp/revaliases
echo "Use the following command to grant a user the ability to send mails:" >> $user_home/ssmtp-install.log
echo "# usermod -a -G mailing <USER>" >> $user_home/ssmtp-install.log
echo "And add an approriate line to /etc/ssmtp/revaliases" >> $user_home/ssmtp-install.log

