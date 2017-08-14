# Fix the hosts file with the preseeded host name

if [[ $net_mode == 'static' ]]; then
	sed -r "s/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+([\\t ]+)ubuntu/$ip4\\1$host_name/g" -i /etc/hosts
else
	sed -r "s/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+([\\t ]+)ubuntu/127.0.0.1\\1$host_name/g" -i /etc/hosts
fi

