# Setup the bash profile

sed 's/#force_color_prompt=.*/force_color_prompt=yes/' /root/.bashrc > $user_home/.bashrc
echo '. $HOME/.bashrc' > $user_home/.bash_profile
chown $user_id:root $user_home/.bash*
chmod 0600 $user_home/.bash*

