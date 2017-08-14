# Post install script header

post_config_file='/media/cdrom/post_config.ini'

function cfgval {
	awk -F '=' "/$1/ {print \$2}" "$post_config_file" | tail -n 1 | tr -d ' "'
}
