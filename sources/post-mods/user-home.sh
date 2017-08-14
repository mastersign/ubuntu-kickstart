# Creating the main users home directory

if [ ! -d $user_home ]; then
	mkdir -m 0700 $user_home
	chown $user_id:root $user_home
fi

