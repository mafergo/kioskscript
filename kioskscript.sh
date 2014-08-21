#!/bin/bash

## Sanickiosk (get it?), a script for building web kiosks
## June 2014
## Tested on Ubuntu Server 14.04 fresh install
##               _,,,,_
##             ,########,
##            ,##'    '##,
##            ## ##  ## ##
##            /# (.)(.) #\
##            \#   _)   #/
##             #,######,#
##             ##, ~~ ,##
##       ,,,,,,'########',,,,,,,
##      #       '######'        #
##     #           by            #
##    #           Scott           #
##   # "the brute-force librarian" #
##  (            Sanicki            )
##   #        ______ ______        #
##    # --  // ~ ~~ Y ~~ ~ \\  -- #
##     (  )// ~~ ~~ | ~~ ~~ \\(  )
##      --// ~ ~ ~~ | ~~~ ~~ \\--
##       //________,|,________\\
##      '----------'-'----------'
## Contact me @ http://scr.im/godzilla8nj
## Make a donation http://links.sanicki.com/tip4sanickiosk
##
## Documentation: http://sanickiosk.org
## Download a ready-to-install ISO of Sanickiosk at: http://links.sanicki.com/sanickiosk-dl
##
## This project replaces:
## http://links.sanicki.com/yln.kiosk
## http://tinyurl.com/ppl-kiosk
##
## To use this script:
## sudo su
## wget http://links.sanicki.com/kioskscript -O kioskscript.sh
## chmod +x kioskscript.sh
## ./kioskscript.sh

# Pretty colors
red='\e[0;31m'
green='\e[1;32m'
blue='\e[1;36m'
NC='\e[0m' # No color

clear
# Determine Ubuntu Version Codename
VERSION=$(lsb_release -cs)

echo -e "${red}Installing operating system updates ${blue}(this may take a while)${red}...${NC}\n"
# Use mirror method
sed -i "1i \
deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION main restricted universe multiverse\n\
deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-updates main restricted universe multiverse\n\
deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-backports main restricted universe multiverse\n\
deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-security main restricted universe multiverse\n\
" /etc/apt/sources.list
# Refresh
apt-get -q=2 update
# Download & Install
apt-get -q=2 dist-upgrade > /dev/null
# Clean
apt-get -q=2 autoremove
apt-get -q=2 clean
echo -e "${green}Done!${NC}\n"

echo -e "${red}Disabling root recovery mode...${NC}\n"
sed -i -e 's/#GRUB_DISABLE_RECOVERY/GRUB_DISABLE_RECOVERY/g' /etc/default/grub
update-grub
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Enabling secure wireless support...${NC}\n"
apt-get -q=2 install --no-install-recommends wpasupplicant > /dev/null
echo -e "${green}Done!${NC}\n"

echo -e "${red}Installing a graphical user interface...${NC}\n"
apt-get -q=2 install --no-install-recommends xorg nodm matchbox-window-manager > /dev/null
# Hide Cursor
apt-get -q=2 install --no-install-recommends unclutter > /dev/null
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Creating kiosk user...${NC}\n"
useradd kiosk -m -d /home/kiosk -p `openssl passwd -crypt kiosk`
# Configure kiosk autologin
sed -i -e 's/NODM_ENABLED=false/NODM_ENABLED=true/g' /etc/default/nodm
sed -i -e 's/NODM_USER=root/NODM_USER=kiosk/g' /etc/default/nodm
echo -e "${green}Done!${NC}\n"

echo -e "${red}Installing and configuring the screensaver...${NC}\n"
apt-get -q=2 install --no-install-recommends xscreensaver xscreensaver-data-extra xscreensaver-gl-extra libwww-perl > /dev/null
# Create .xscreensaver
echo '
# XScreenSaver Preferences File

captureStderr:	False
timeout:	0:00:10
lock:		False
splash:		False
fade:		True
fadeSeconds:	0:00:03
fadeTicks:	20
dpmsEnabled:	False
chooseRandomImages: True
imageDirectory:	/home/kiosk/screensavers
mode:		one
selected:	0
programs:	glslideshow -root
' > /home/kiosk/.xscreensaver
# Create the screensaver directory
mkdir /home/kiosk/screensavers
# Add a sample image
wget -q http://beginwithsoftware.com/wallpapers/archive/Various/images/free_desktop_wallpaper_logo_space_for_rent_1024x768.gif -O /home/kiosk/screensavers/deleteme.gif
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Installing the browser ${blue}(Opera)${red}...${NC}\n"
echo "
## Ubuntu Partners
deb http://archive.canonical.com/ $VERSION partner
"  >> /etc/apt/sources.list
wget -O - http://deb.opera.com/archive.key | apt-key add -
echo '
## Opera
deb http://deb.opera.com/opera/ stable non-free
'  >> /etc/apt/sources.list
apt-get -q=2 update
apt-get -q=2 -y install --force-yes --no-install-recommends opera > /dev/null
apt-get -q=2 install --no-install-recommends flashplugin-installer icedtea-7-plugin ttf-liberation > /dev/null # flash, java, and fonts
mkdir /home/kiosk/.opera
# Delete default Opera RSS Feed Readers
find /usr/share/opera -name "feedreaders.ini" -print0 | xargs -0 rm -rf
# Delete default Opera Webmail Providers
find /usr/share/opera -name "webmailproviders.ini" -print0 | xargs -0 rm -rf
# Overwrite default Opera Bookmarks
find /usr/share/opera -name "bookmarks.adr" -print0 | xargs -0 rm -rf
# Delete default Opera Speed Dial
find /usr/share/opera -name "standard_speeddial.ini" -print0 | xargs -0 rm -rf
# Create an Opera Speed Dial save file
echo '
Opera Preferences version 2.1
; Do not edit this file while Opera is running
; This file is stored in UTF-8 encoding

[Background]
Enabled=0

[Speed Dial 1]
Title=Sanickiosk Documentation
Url=http://sanickiosk.org
' > /home/kiosk/.opera/speeddial.sav
# Create the Opera filter
echo '
[prefs]
prioritize excludelist=1

[include]
*.*

[exclude]
' > /home/kiosk/.opera/urlfilter.ini
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Creating Sanickiosk Scripts...${NC}\n"
mkdir /home/kiosk/.sanickiosk
# Create .xsession
echo '
#!/bin/bash

# Import variables
. /home/kiosk/.sanickiosk/screensaver.cfg
. /home/kiosk/.sanickiosk/browser.cfg

# Uncomment to run touchscreen calibration on next boot
#xterm xinput_calibrator

# Disable right-click
	if [ $nocontextmenu != "False" ]
	then xmodmap -e "pointer = 1 2 99"
	fi

# Autorun screensaver on login
if [ $xscreensaver_enable = "True" ]
then
	# Look for new screensaver images
	rm .xscreensaver-getimage.cache

	# Write latest screensaver switches
	bash /home/kiosk/.sanickiosk/set_glslideshow_switches.sh

	# Read latest screensaver switches
	screensaver_switches=`cat /home/kiosk/.sanickiosk/glslideshow_switches.cfg`

	# Set screensaver timeout
	sed -i "/timeout:/c\timeout:	$xscreensaver_idle" /home/kiosk/.xscreensaver
	# Set glslideshow switches
	sed -i "/programs:/c\programs:	glslideshow -root $screensaver_switches" /home/kiosk/.xscreensaver
	xscreensaver -nosplash &
else
	xset s off # Disable screensaver
	xset -dpms # Disable DPMS (Energy Star) features
	xset s noblank # Do not blank the screen
fi

# Get screen resolution
res=$(xrandr -q | awk -F'"'"'current'"'"' -F'"'"','"'"' '"'"'NR==1 {gsub("( |current)","");print $2}'"'"')

# Nuke it from orbit
rm -r /home/kiosk/.opera
mkdir /home/kiosk/.opera

# Write latest operaprefs.ini
sh /home/kiosk/.sanickiosk/operaprefs.sh

# Avoid Opera Welcome screen
touch -t 201401010001 /home/kiosk/.opera/operaprefs.ini

# Write latest toolbar
sh /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar_builder.sh

# Restore keyboard shortcuts
mkdir /home/kiosk/.opera/keyboard
cp /home/kiosk/.sanickiosk/sanickiosk_keyboard.ini /home/kiosk/.opera/keyboard/

# Write latest browser switches
bash /home/kiosk/.sanickiosk/set_opera_switches.sh

# Read latest browser switches
browser_switches=`cat /home/kiosk/.sanickiosk/opera_switches.cfg`

# Start browser killer
sh /home/kiosk/.sanickiosk/browser_killer.sh &

# Start window manager
matchbox-window-manager &

# Relaunch browser if closed
while true; do
	# Restore Opera Speed Dial
	cp /home/kiosk/.opera/speeddial.sav /home/kiosk/.opera/speeddial.ini

	# Delete Opera Bookmarks
	rm /home/kiosk/.opera/bookmarks.adr

	# Relaunch Opera
	if [ $kioskspeeddial = "True" ]
	then
		opera -geometry $res+0+0 $browser_switches
	else
		opera -geometry $res+0+0 $browser_switches $home_url
	fi
	sleep 5s
done
' > /home/kiosk/.xsession
# Create file to hold all screensaver variables
touch /home/kiosk/.sanickiosk/screensaver.cfg
# Create file to hold all GLSlideshow launch switches
touch /home/kiosk/.sanickiosk/glslideshow_switches.cfg
# Create file to hold all browser variables
touch /home/kiosk/.sanickiosk/browser.cfg
# Create file to hold Opera launch switches
touch /home/kiosk/.sanickiosk/opera_switches.cfg
# Create GLSlideshow switches script
echo '
#!/bin/bash

# Import variables
. /home/kiosk/.sanickiosk/screensaver.cfg

switches=""
for option in glslideshow_duration glslideshow_pan glslideshow_fade glslideshow_zoom glslideshow_clip ; do
	value=${!option}
	delete="glslideshow_"
	option=${option#${delete}}
	if [ $option != "clip" ]
	then
		if [ -n "$value" ]
		then
			switches=$switches" -"$option" "$value
		fi
	else
		if [ $value="True" ]
		then
			switches=$switches" -clip"
		else
			switches=$switches" -letterbox"
		fi
	fi
done

echo $switches > /home/kiosk/.sanickiosk/glslideshow_switches.cfg
' > /home/kiosk/.sanickiosk/set_glslideshow_switches.sh
chmod +x /home/kiosk/.sanickiosk/set_glslideshow_switches.sh
# Create operaprefs.ini
echo '
#!/bin/bash

# Import variables
. /home/kiosk/.sanickiosk/browser.cfg

echo "
Opera Preferences version 2.1
; Do not edit this file while Opera is running
; This file is stored in UTF-8 encoding
" > /home/kiosk/.opera/operaprefs.ini

# Empty cache when exiting
if [ $empty_on_exit = "True" ]
then
	echo "
[Disk Cache]
Empty On Exit=1
	" >> /home/kiosk/.opera/operaprefs.ini
fi

echo "
[State]
Accept License=1

[User Prefs]
Auto Dropdown=0
Keyboard Configuration=/home/kiosk/.opera/keyboard/sanickiosk_keyboard.ini
Toolbar Configuration=/home/kiosk/.opera/toolbar/sanickiosk_toolbar.ini
Speed Dial State=2
Show Startup Dialog=0
Show Crash Log Upload Dialog=0
Show Problem Dialog=0
" >> /home/kiosk/.opera/operaprefs.ini

# Delete cookies when exiting
if [ $accept_cookies_session_only = "True" ]
then
	echo "
Accept Cookies Session Only=1
	" >> /home/kiosk/.opera/operaprefs.ini
fi

# Disable opera:config
if [ $disable_config_url = "True" ]
then
	echo "
Enable config URL=false
	" >> /home/kiosk/.opera/operaprefs.ini
fi

# Custom User-Agent
if [ "$custom_user_agent" != "None" ]
then
	echo Custom User-Agent=$custom_user_agent >> /home/kiosk/.opera/operaprefs.ini
fi

# Set Home Page
if [ $kioskspeeddial = "False" ]
then
	echo "Startup Type=2" >> /home/kiosk/.opera/operaprefs.ini
	home="Home URL="$home_url
	echo $home >> /home/kiosk/.opera/operaprefs.ini
else
	echo "
Startup Type=4
Speed Dial State=2
Home URL=
	" >> /home/kiosk/.opera/operaprefs.ini
fi
' > /home/kiosk/.sanickiosk/operaprefs.sh
chmod +x /home/kiosk/.sanickiosk/operaprefs.sh
# Create toolbar configuration script
mkdir /home/kiosk/.sanickiosk/toolbar
# Toolbar Part 1 of 4
echo '
﻿﻿Opera Preferences version 2.1
; Do not edit this file while Opera is running
; This file is stored in UTF-8 encoding

[INFO]
NAME=Sanickiosk

[Status Toolbar.alignment]
Alignment=0
Auto alignment=0
Old visible alignment=4
Collapse=1
' > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-1.cfg
# Toolbar Part 2 of 4
echo '
[Document Toolbar.alignment]
Alignment=
Auto alignment=0
Old visible alignment=2
Collapse=1
' > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-2.cfg
# Toolbar Part 3 of 4
echo '
#!/bin/bash
# Import variables
. /home/kiosk/.sanickiosk/browser.cfg

echo "[Document Toolbar.content]" > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
if [ $hide_home = "False" ]
then
	if [ $kioskspeeddial = "False" ]
	then
		echo "Button0, \"Home\"=\"Go to homepage,,,,Go to homepage\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
	else
		echo "Button0, \"Home\"=\"New page,,,,Go to homepage\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
	fi
fi
if [ $hide_back = "False" ]
then
	echo "Button1, \"Back\"=\"Back,,,,Back\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_forward = "False" ]
then
	echo "Button2, \"Forward\"=\"Forward,,,,Forward\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_reload = "False" ]
then
	echo "Button3, \"Stop_Reload\"=\"Stop | Reload,,,Reload\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_addressbar = "False" ]
then
	echo "Address4" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_find = "False" ]
then
	echo "Button5, \"Find\"=\"Find,,,,Find\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_zoom = "False" ]
then
	echo "ZoomSlider6" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_ppreview = "False" ]
then
	echo "Button7, \"Print preview\"=\"Print preview,,,,Cascade\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_print = "False" ]
then
	echo "Button8, \"Print\"=\"Print document,,,,Print document\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
if [ $hide_reset = "False" ]
then
	echo "Button9, \"Reset Kiosk\"=\"Zoom to,100,,,Restart transfer > Exit\"" >> /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.cfg
fi		
' > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.sh
# Toolbar Part 4 of 4
echo '
[Pagebar.alignment]
Alignment=0
Auto alignment=0
Old visible alignment=2
Collapse=1

[Pagebar Tail.content]
' > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-4.cfg
# Create toolbar builder script
echo '
#!/bin/bash
# Import variables
. /home/kiosk/.sanickiosk/browser.cfg

if [ $hide_toolbar = "False" ]
then
	# Show Toolbar
	sed -i "/Alignment=/c\Alignment=2" /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-2.cfg
	# Generate toolbar buttons
	sh /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-3.sh
else
	# Hide Toolbar
	sed -i "/Alignment=/c\Alignment=0" /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-2.cfg
fi
mkdir /home/kiosk/.opera/toolbar/
cat /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar-*.cfg > /home/kiosk/.opera/toolbar/sanickiosk_toolbar.ini
' > /home/kiosk/.sanickiosk/toolbar/sanickiosk_toolbar_builder.sh
# Create keyboard shortcuts
echo '
Opera Preferences version 2.1
; Do not edit this file while Opera is running
; This file is stored in UTF-8 encoding

[Version]
File Version=1

[Info]
Description=Sanickiosk Keyboard Shortcuts
Author=Rob Clayton
Version=1
NAME=ajenti

[Application]
F1 shift="Open URL in new page, "https://127.0.0.1""
' > /home/kiosk/.sanickiosk/sanickiosk_keyboard.ini
# Create Opera switches script
echo '
#!/bin/bash

# Import variables
. /home/kiosk/.sanickiosk/browser.cfg

switches=""
for option in kioskmode fullscreen nokeys nomenu nodownload noprint nomaillinks ; do
	value=${!option}
	if [ $value != "False" ]
	then
		switches=$switches" -"$option
	fi
done

echo $switches > /home/kiosk/.sanickiosk/opera_switches.cfg
' > /home/kiosk/.sanickiosk/set_opera_switches.sh
chmod +x /home/kiosk/.sanickiosk/set_opera_switches.sh
# Create browser killer
apt-get -q=2 install --no-install-recommends xprintidle > /dev/null
echo '
#!/bin/bash
# Import variables
. /home/kiosk/.sanickiosk/browser.cfg

# Wanted trigger timeout in milliseconds.
IDLE_TIME=$(($browser_idle*60*1000))

# Sequence to execute when timeout triggers.
trigger_cmd() {
	killall opera
}

sleep_time=$IDLE_TIME
triggered=false

# ceil() instead of floor()
while sleep $(((sleep_time+999)/1000)); do
	idle=$(xprintidle)
	if [ $idle -ge $IDLE_TIME ]
	then
		if ! $triggered
		then
			trigger_cmd
			triggered=true
			sleep_time=$IDLE_TIME
		fi
	else
		triggered=false
		# Give 100 ms buffer to avoid frantic loops shortly before triggers.
		sleep_time=$((IDLE_TIME-idle+100))
	fi
done
' > /home/kiosk/.sanickiosk/browser_killer.sh
chmod +x /home/kiosk/.sanickiosk/browser_killer.sh
# Set correct user and group permissions for /home/kiosk
chown -R kiosk:kiosk /home/kiosk/
echo -e "${green}Done!${NC}\n"

echo -e "${red}Adding the browser-based system administration tool ${blue}(Ajenti)${red}...${NC}\n"
wget -q http://repo.ajenti.org/debian/key -O- | apt-key add -
echo '
## Ajenti
deb http://repo.ajenti.org/ng/debian main main ubuntu
'  >> /etc/apt/sources.list
apt-get -q=2 update && apt-get -q=2 install --no-install-recommends ajenti > /dev/null
service ajenti stop
# Changing to default https port
sed -i 's/"port": 8000/"port": 443/' /etc/ajenti/config.json
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Adding Sanickiosk plugins to Ajenti...${NC}\n"
apt-get -q=2 install --no-install-recommends unzip > /dev/null
wget -q https://github.com/sanicki/sanickiosk_plugins/archive/master.zip -O sanickiosk_plugins-master.zip
unzip -qq sanickiosk_plugins-master.zip
mv sanickiosk_plugins-master/* /var/lib/ajenti/plugins/
rm -r sanickiosk_plugins-master*
echo -e "${green}Done!${NC}\n"

echo -e "${red}Installing audio...${NC}\n"
apt-get -q=2 install --no-install-recommends alsa > /dev/null
adduser kiosk audio
echo -e "\n${green}Done!${NC}\n"

echo -e "${red}Installing print server...${NC}\n"
tasksel install print-server > /dev/null
usermod -aG lpadmin administrator
usermod -aG lp,sys kiosk
echo '
LogLevel debug
SystemGroup lpadmin
Port 80
Listen /var/run/cups/cups.sock
Browsing On
BrowseOrder allow,deny
BrowseAddress @LOCAL
<Location />
  Order allow,deny
  Allow all
</Location>
<Location /admin>
  Order allow,deny
  Allow all
</Location>
<Location /admin/conf>
  Order allow,deny
  Allow all
</Location>
'  > /etc/cups/cupsd.conf
echo -e "${green}Done!${NC}\n"

echo -e "${red}Installing touchscreen support...${NC}\n"
apt-get -q=2 install --no-install-recommends xserver-xorg-input-multitouch xinput-calibrator > /dev/null
echo -e "${green}Done!${NC}\n"

echo -e "${red}Adding the customized image installation maker ${blue}(Mondo Rescue)${red}...${NC}\n"
wget -q -O - ftp://ftp.mondorescue.org/ubuntu/12.10/mondorescue.pubkey | apt-key add -
echo '
## Mondo Rescue
deb ftp://ftp.mondorescue.org/ubuntu 12.10 contrib
'  >> /etc/apt/sources.list
apt-get -q=2 update && apt-get -q=2 install --no-install-recommends --force-yes mondo > /dev/null
echo -e "${green}Done!${NC}\n"

echo -e "${green}Reboot?${NC}"
select yn in "Yes" "No"; do
        case $yn in
                Yes )
                        reboot ;;
                No )
                        break ;;
        esac
done
