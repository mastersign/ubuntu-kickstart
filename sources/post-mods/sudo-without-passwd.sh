# Setup sudo without password

echo "$user_name ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/01_$user_name

