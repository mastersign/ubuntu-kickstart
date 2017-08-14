#!/bin/bash

version="1.0"

# Needs to be run with root previledges because
# of the loop driver for writing the output ISO image.
if [[ $EUID != 0 ]]; then
	sudo "$0" "$@"
	exit $?
fi

# =============================================================================

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ==============================
# SETUP CONFIGURATION PARAMETERS
# ==============================

verbose=0                                                      # v
dry_run=0                                                      # t, T

def_config_file="$DIR/sources/default_config.ini"
param_names=( \
	ubuntu_version result_iso_file \
	host_name user_name user_fullname user_passwd authorized_keys_file \
	packages_file post_mods_file pre_script_file post_script_file
	timezone default_locale keyboard
	net_mode ip4 ip4_netmask ip4_gateway ip4_nameserver \
)

# mod_ip_D <ip> <last byte>
function mod_ip_D {
	if [[ $1 =~ ^([0-9]*)\.([0-9]*)\.([0-9]*)\.([0-9]*)$ ]]; then
		echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.$2"
	fi
}

while getopts "hVvtTc:o:H:N:n:P:k:p:M:b:a:si:m:g:d:" OPT; do
	case $OPT in
		h)
			headline="Ubuntu Kickstart Generator v$version"
			underline=$(printf %s "$headline" | tr -c '-' '[-*]')
			echo -e "\n$headline\n$underline\n"
			echo "Usage: $( basename ${BASH_SOURCE[0]} ) [FLAGS] [OPTIONS]"
			echo "Flags:"
			echo "  -h print this help and exit"
			echo "  -V print the tool version and exit"
			echo "  -v for printing the configuration before execution"
			echo "  -t for dry run: no ISO compilation"
			echo "  -T for very dry run: just resource download and extraction"
			echo "  -s for static IP4 configuration instead of DHCP"
			echo "Options:"
			echo "  -c <path to config file> (default: none)"
			echo "  -o <path to output ISO file> (default: out/custom-ubuntu-server.iso)"
			echo "  -H <hostname> (default: 'custom-ubuntu')"
			echo "  -N <main username> (default: 'main')"
			echo "  -n <main full username> (default: 'Administrator')"
			echo "  -P <main user password> (default: 'mainadmin')"
			echo "  -k <path to authorized keys file> (default: sources/id_rsa.pub)"
			echo "  -p <path to packages list file> (default: sources/packages.list)"
			echo "  -M <path to post-mod list file> (default: sources/postmods.list)"
			echo "  -b <path to pre install script> (default: sources/pre.sh)"
			echo "  -a <path to post install script> (default: sources/post.sh)"
			echo "  -i <static IP4 address> (default: '192.168.0.128')"
			echo "  -m <static IP4 netmask> (default: '255.255.255.0')"
			echo "  -g <static IP4 gateway> (default: '192.168.0.1')"
			echo "  -d <static IP4 nameserver> (default: '192.168.0.1')"
			echo ""
			exit
			;;
		v)
			verbose=1
			;;
		V)
			echo "$version"
			exit
			;;
		t)
			dry_run=1
			;;
		T)
			dry_run=2
			;;
    c)
			config_file=$OPTARG
			;;
		o)
			result_iso_file=$OPTARG
			;;
		H)
			host_name=$OPTARG
			;;
		N)
			user_name=$OPTARG
			;;
		n)
			user_fullname=$OPTARG
			;;
		P)
			user_passwd=$OPTARG
			;;
		k)
			authorized_keys_file=$OPTARG
			;;
		p)
			packages_file=$OPTARG
			;;
		M)
			post_mods_file=$OPTARG
			;;
		b)
			pre_script_file=$OPTARG
			;;
		a)
			post_script_file=$OPTARG
			;;
		s)
			net_mode='static'
			;;
		i)
			ip4=$OPTARG
			ip4_gateway=$(mod_ip_D $ip4 1)
			ip4_nameserver=$(mod_ip_D $ip4 1)
			if [[ $ip4 =~ ^0*10\.[0-9]*\.[0-9]*\.[0-9]*$ ]]; then
				ip4_netmask='255.0.0.0'
			elif [[ $ip4 =~ ^192\.168\.[0-9]*\.[0-9]*$ ]]; then
				ip4_netmask='255.255.255.0'
			fi
			;;
		m)
			ip4_netmask=$OPTARG
			;;
		g)
			ip4_gateway=$OPTARG
			;;
		d)
			ip4_nameserver=$OPTARG
			;;
		*)
			echo "Invalid option: -$OPTARG" >&2
			exit
			;;
	esac
done

function ini_value {
	local v=$(awk -F '=' "/$2/ {print \$2}" "$1" | tail -n 1 | tr -d ' "')
	# check if value is relative path to a file
	if [[ "$v" != "" && "$2" = *_file && "$v" != /* ]]; then
		# remove leading './'
		if [[ "$v" = ./* ]]; then
			local v="${v:2}"
		fi
		# make it absolute with INI file location
		local v="$(dirname "$1")/$v"
		if [[ -f "$v" ]]; then
			local v=$(realpath "$v")
		fi
	fi
	echo "$v"
}

function cmdline_value {
	local v=${!1}
	# check if value is a relative path to a file
	if [[ "$v" != "" && "$1" = *_file && "$v" != /* ]]; then
		# remove leading './'
		if [[ "$v" = ./* ]]; then
			local v="${v:2}"
		fi
		# make it absolute with current working dir
		local v="$(pwd)/$v"
		if [[ -f "$v" ]]; then
			local v=$(realpath "$v")
		fi
	fi
	echo "$v"
}

# complete parameters
# by overlaying command line args, config values and default values
for p in ${param_names[@]}; do
	# load default value from default config file
	def_v=$(ini_value "$def_config_file" $p)
	# check if custom configuration is given
	if [[ -f "$config_file" ]]; then
		# read value from custom config file
		cfg_v=$(ini_value "$config_file" $p)
	else
		cfg_v=''
	fi
	cmd_v=$(cmdline_value $p)

	# fall through command line arg, custom config, and default config
	# and set variable accordingly
	printf -v "$p" "${cmd_v:-${cfg_v:-$def_v}}"
done

if [[ $verbose -eq '1' || $dry_run -eq '1' ]]; then
	echo "Configuration"
	echo "----------------------------------------"
	if [[ -f "$config_file" ]]; then
		echo "Config File:           $config_file"
	fi
	echo "Ubuntu Version:        $ubuntu_version"
	echo "Output ISO File:       $result_iso_file"
	echo "Hostname:              $host_name"
	echo "Username:              $user_name"
	echo "Full Username:         $user_fullname"
	echo "Authorized Keys File:  $authorized_keys_file"
	echo "Packages List:         $packages_file"
	echo "Post-Mods List:        $post_mods_file"
	echo "Pre Install Script:    $pre_script_file"
	echo "Post Install Script:   $post_script_file"
	echo "Timezone:              $timezone"
	echo "Default Locale:        $default_locale"
	echo "Network Mode:          $net_mode"
	if [[ $net_mode == 'static' ]]; then
		echo "IP4 Address:           $ip4"
		echo "IP4 Netmask:           $ip4_netmask"
		echo "IP4 Gateway:           $ip4_gateway"
		echo "IP4 Nameserver:        $ip4_nameserver"
	fi
	echo "----------------------------------------"
fi

# ===================
# PREPARING RESOURCES
# ===================

cache_dir="$DIR/cache"
if [[ ! -d "$cache_dir" ]]; then
	mkdir -m 0777 "$cache_dir"
fi
if [[ ! -d "$DIR/out" ]]; then
	mkdir -m 0777 "$DIR/out"
fi
iso_file="$cache_dir/ubuntu-$ubuntu_version-server-amd64.iso"
image_dir="$cache_dir/ubuntu-$ubuntu_version-server-amd64"
tmp_dir="$DIR/tmp"

if [[ -d "$tmp_dir" ]]; then
	echo "Preparing..."
	umount "$tmp_dir"
	rm -rf "$tmp_dir/"
fi

if [[ ! -f "$iso_file" ]]; then
	echo "Downloading Ubuntu $ubuntu_version Server installer ISO..."
	iso_url="http://releases.ubuntu.com/$ubuntu_version/ubuntu-$ubuntu_version-server-amd64.iso"
	wget -O "$iso_file" "$iso_url"
	chmod 0666 "$iso_file"
fi

echo "Ubuntu $ubuntu_server Server installer image ready."

if [[ ! -d "$image_dir" ]]; then
	echo "Extracting ISO file..."
	mkdir "$tmp_dir"
	mount -o loop "$iso_file" "$tmp_dir"
	mkdir "$image_dir"
	rsync -a -H --exclude=TRANS.TBL "$tmp_dir/" "$image_dir"
	umount "$tmp_dir"
	rm -rf "$tmp_dir/"
fi

echo "Ubuntu $ubuntu_version Server installer image extracted."

# EXIT IF VERY DRY RUN

if [[ $dry_run -eq '2' ]]; then
	exit
fi

# ====================
# ADAPTING IMAGE FILES
# ====================

echo "Adapting image..."

echo "- Setting up installer language"
echo "en\n" > "$image_dir/isolinux/lang"

echo "- Copying post config file"
if [[ -f "$post_config_file" ]]; then
	cp "$post_config_file" "$image_dir/post_config.ini"
else
	echo -e "\nWARNING: Did not find the post config file: '$post_config_file'!\n"
fi

# ----------------------
# WRITING KICKSTART FILE
# ----------------------

# https://help.ubuntu.com/lts/installation-guide/i386/ch04s06.html
# http://docs.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/ch-kickstart2.html

kscfg="$image_dir/ks.cfg"

echo "- Configuring Kick Start"
echo "lang $default_locale
langsupport $default_locale en_US.UTF-8 --default=$default_locale
keyboard $keyboard
mouse
timezone --utc $timezone
rootpw --disabled
user $user_name --fullname=\"$user_fullname\" --password=\"$user_passwd\" --uid=1000
reboot
text
install
cdrom
bootloader --location=mbr
zerombr yes
clearpart --all --initlabel
part / --fstype ext4 --size 1 --grow --asprimary
part swap --recommended
auth  --useshadow
firewall --disabled
skipx" > "$kscfg"
if [[ $net_mode == 'static' ]]; then
	echo "network --bootproto=static --ip=$ip4 --netmask=$ip4_netmask --gateway=$ip4_gateway --nameserver=$ip4_nameserver --device=eth0" >> "$kscfg"
else
	echo "network --bootproto=dhcp --device=eth0" >> "$kscfg"
fi

if [[ -f "$packages_file" ]]; then
	echo -e "\n%packages" >> "$kscfg"
	cat "$packages_file" >> "$kscfg"
fi

if [[ -f "$pre_script_file" ]]; then
	echo -e "\n%pre --interpreter=/bin/bash --log=/root/pre-install.log" >> "$kscfg"
	echo -e "\n## ==================\n## PRE INSTALL SCRIPT\n## ==================\n" >> "$kscfg"
	cat "$pre_script_file" >> "$kscfg"
fi

echo -e "\n%post --interpreter=/bin/bash --log=/root/post-install.log" >> "$kscfg"
echo -e "\n## ===================\n## POST INSTALL SCRIPT\n## ===================\n" >> "$kscfg"
echo "echo '$host_name' > /etc/hostname" >> "$kscfg"
echo "host_name='$host_name'" >> "$kscfg"
echo "user_name='$user_name'" >> "$kscfg"
echo "user_fullname='$user_fullname'" >> "$kscfg"
echo "user_home='/home/$user_name'" >> "$kscfg"
echo "default_locale='$default_locale'" >> "$kscfg"
echo "net_mode='$net_mode'" >> "$kscfg"
if [[ $net_mode == 'static' ]]; then
	echo "ip4='$ip4'" >> "$kscfg"
fi

# Note: The UID 1000 is used for the not yet created main user
#       from the kickstart configuration.

echo "user_id='1000'" >> "$kscfg"

post_head_file="$DIR/sources/post_head.sh"
if [[ -f "$post_head_file" ]]; then
	echo "" >> "$kscfg"
	cat "$post_head_file" >> "$kscfg"
	echo "" >> "$kscfg"
fi

if [[ -f "$post_mods_file" ]]; then
	for line in `sed '/^$/d' "$post_mods_file"`; do
		post_mod_file="$DIR/sources/post-mods/${line}.sh"
		if [[ -f "$post_mod_file" ]]; then
			echo -e "# POST MOD $line\n" >> "$kscfg"
			cat "$post_mod_file" >> "$kscfg"
		else
			echo -e "# POST MOD $line NOT FOUND\n" >> "$kscfg"
		fi
	done
fi

if [[ -f "$post_script_file" ]]; then
	echo -e "\n# CUSTOM POST SCRIPT\n" >> "$kscfg"
	cat "$post_script_file" >> "$kscfg"
fi

echo -e "\n# Adapt access rights for logs in home" >> "$kscfg"
echo 'chown $user_id:root $user_home/*.log' >> "$kscfg"
echo "" >> "$kscfg"
echo 'chmod 0666 $user_home/*.log' >> "$kscfg"
echo "" >> "$kscfg"

# ------------------------------------
# WRITING INSTALLER MENU CONFIGURATION
# ------------------------------------

# http://www.syslinux.org/wiki/index.php?title=Menu
# http://www.syslinux.org/wiki/index.php?title=Config

echo "- Configure installer arguments"
echo 'default install
label install
	menu label ^Unattended Install
	menu default
	kernel /install/vmlinuz
	append file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/initrd.gz ks=cdrom:/ks.cfg ---' \
	> "$image_dir/isolinux/txt.cfg"

echo "- Activate automatic installer start"
sed -i 's/timeout [0-9]*/timeout 10/' $image_dir/isolinux/isolinux.cfg

echo "- Deploying authorized keys"
cp $authorized_keys_file $image_dir/authorized_keys

# EXIT IF DRY RUN

if [[ $dry_run -eq '1' ]]; then
	exit
fi

# ============
# CREATING ISO
# ============

echo "Creating ISO image..."
pushd "$image_dir"
genisoimage -o "$result_iso_file" -r -J -no-emul-boot -boot-load-size 4 \
	-boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat \
	.
chmod 0666 "$result_iso_file"
popd

# =============================================================================

echo "Finished."
