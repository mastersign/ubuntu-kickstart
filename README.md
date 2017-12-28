Ubuntu Kickstarter
==================

> This project contains a shell script for creating an ISO image
> for the unattended installation of Ubuntu Linux.

Usage
-----

The main script is: `prepare-server-image.sh`

It makes use of the loop driver for ISO file systems with `mount`
to extract the files from the downloaded installer ISO file.
Therefore, it must be run with root privileges.

```sh
# Download installer ISO file
# Extract the installer files
# Write Kickstarter configuration
# Create the custom installer image as a new ISO file

sudo ./prepare-server-image.sh -v -H my-server \
    -N peter -P In1ti4lPa5sw0rd \
    -s -i 192.168.77.12 -o ./out/my-server.iso
```

You have multiple points to parameterize the unattended installation:

* Use the command line parameters.  
  E.g. Use your own public key for SSH login without a password.  
  Use the command line argument `-k <path>` to specify the public key file.
* Specifying a config file with additional parameters.  
  Take a look at `sources/default_config.ini` for the default values
  and a template for your own config file.
* Write and reference a custom package-list
  with the command line option `-p <path>`.  
  Take a look at `sources/packages.list` for the default list.
* Select included post-mods with a post-mod-list
  by using the command line option `-M <path>`.  
  Take a look at `sources/postmods.list` for the default list
  and `sources/post-mods/*.sh` for their implementation.
* Reference custom pre- and post-install-scripts
  with the command line options `-b <path>` and `-a <path>`.

CLI Reference
---------

```
Ubuntu Kickstart Generator v1.0
-------------------------------

Usage: prepare-server-image.sh [FLAGS] [OPTIONS]
Flags:
  -h print this help and exit
  -V print the tool version and exit
  -v for printing the configuration before execution
  -t for dry run: no ISO compilation
  -T for very dry run: just resource download and extraction
  -s for static IP4 configuration instead of DHCP
Options:
  -c <path to config file> (default: none)
  -o <path to output ISO file> (default: out/custom-ubuntu-server.iso)
  -H <hostname> (default: 'custom-ubuntu')
  -N <main username> (default: 'main')
  -n <main full username> (default: 'Administrator')
  -P <main user password> (default: 'mainadmin')
  -k <path to authorized keys file> (default: sources/id_rsa.pub)
  -p <path to packages list file> (default: sources/packages.list)
  -M <path to post-mod list file> (default: sources/postmods.list)
  -b <path to pre install script> (default: sources/pre.sh)
  -a <path to post install script> (default: sources/post.sh)
  -i <static IP4 address> (default: '192.168.0.128')
  -m <static IP4 netmask> (default: '255.255.255.0')
  -g <static IP4 gateway> (default: '192.168.0.1')
  -d <static IP4 nameserver> (default: '192.168.0.1')
```

Configuration File Properties
-----------------------------

Config files have a simple syntax with one property per line.
The property name and value are separated by an equal sign.
Around the equal sign spaces are allowed.
Every thing behind the equal sign is used as the value.
Spaces and double quotes are trimmed off.
Lines without an equal sign in them are ignored.

```
property_name = "value"
```

Properties with a name ending at `_file` are treated specially.
Their value is interpreted as a filesystem path.
If the path does not begin with a root slash `/`,
they are made absolute by appending them to the location
of the config file.

### Basic Configuration

* `ubuntu_version` (_16.04.3_)  
  The version of the Ubuntu ISO to download and use as base for customization.
* `result_iso_file` (_../out/custom-ubuntu-server.iso_)  
  A path to the output ISO file.
  If the path is relative, it is resolved relative to the location of the config file.

### Host Configuration

* `host_name`(_custom-ubuntu_)  
  The host name of the system to install.
* `user_name` (_main_)  
  The name of the main user in the system to install.
* `user_fullname` (_Administrator_)  
  The display name of the main user in the system to install.
* `user_passwd` (_mainadmin_)  
  The initial password of the main user in the system to install.
  In most cases you should change that after the installation right away.
* `packages_file` (_packages.list_)  
  A path to a text file with one debian package name per line.
  All packages listet in this file will be installed during the installation.
  If this path is relative, it is resolved relative to the location of the config file.
* `post_mods_file` (_postmods.list_)  
  A path to a text file with one post-mod name per line.
  All post-mods listet in this file will be run during the installation.
  If this path is relative, it is resolved relative to the location of the config file.
* `pre_script_file` (_pre.sh_)  
  A path to a BASH script file, which is to run before the Linux installation is executed.
  If this path is relative, it is resolved relative to the location of the config file.
* `post_script_file` (_post.sh_)  
  A path to a BASH script file, which is to run after the Linux installation,
  the package installation, and the post-mod execution.
  If this path is relative, it is resolved relative to the location of the config file.

### Localization

* `timezone` (_Europe/Berlin_)  
  The timezone is passed to Kickstart.
* `default_locale` (_en_US.UTF-8_)  
  The default locale is passed to Kickstart.
* `keyboard` (_en_)  
  The keyboard layout is passed to Kickstart
  and used by the post-mod `keyboard-layout` to apply additional keyboard customization.

### Network Configuration

* `net_mode` (_dhcp_)  
  The network mode can be `static` or `dhcp`.
* `ip4` (_192.168.0.128_)  
  The static IP4 address of the system to install.
  Takes only effect if the `net_mode` is set to `static`.
* `ip4_netmask` (_255.255.255.0_)  
  The IP4 network mask for the system to install.
  Takes only effect if the `net_mode` is set to `static`.
* `ip4_gateway` (_192.168.0.1_)  
  The gateway for IP4 connections.
  Takes only effect if the `net_mode` is set to `static`.
* `ip4_nameserver` (_192.168.0.1_)  
  The primary DNS resolver for IP4 connections.
  Takes only effect if the `net_mode` is set to `static`.

### SSH Key

The following properties are used by the post-mod `ssh-key`.
Which sets up login without a password for the main user.

* `authorized_keys_file` (_id_rsa.pub_)  
  A path to a public SSH key file, which is copied to the main users `authorized_keys` file.
  If this path is relative, it is resolved relative to the location of the config file.

# sSMTP Configuration

The following properties are used by the post-mod `ssmtp`.
It is configuring the system to deliver mails (e.g. from a cron job) via an arbitrary SMTP server.

* `ssmtp_mailhub` (_your-domain:587_)  
  The host name and port of a SMTP server for delivering system mails.
* `ssmtp_auth_user` (_mailuser_)  
  A user name to authenticate to the SMTP server.
* `ssmtp_auth_pass`  (_mailpassword_)  
  A password to authenticate to the SMTP server.
* `ssmtp_use_tls` (_YES_)  
  A switch to indicate if the connection to the SMTP server is encrypted with TLS.
* `ssmtp_use_starttls` (_YES_)  
  A switch to indicate if STARTTLS must be used with the SMTP server.
* `ssmtp_from_line_override` (_NO_)  
  A switch to indicate if the FROM line in the mail should be overridden by a custom address.
* `ssmtp_from_address` (_admin@your-domain_)  
  A custom email address to use when overriding the FROM line in sent emails.
