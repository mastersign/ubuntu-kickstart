# Configure language specific keyboard layout

if [[ "$keyboard" = "de" ]]; then
	echo '# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
XKBOPTIONS="terminate:ctrl_alt_bksp"
BACKSPACE="guess"' \
		>/etc/default/keyboard
fi
