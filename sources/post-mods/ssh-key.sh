# Setup SSH login without password for the main user

ssh_dir="$user_home/.ssh"
mkdir -m 0750 $ssh_dir
chown -R $user_id:root $ssh_dir
cp /media/cdrom/authorized_keys $ssh_dir/authorized_keys
chmod 0640 $ssh_dir/authorized_keys
chown $user_id:root $ssh_dir/authorized_keys

