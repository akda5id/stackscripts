#!/bin/bash

# <UDF name="sudo_user" label="username for sudo user" />
# SUDO_USER=
#
# <UDF name="sudo_user_password" label="password for sudo user" />
# SUDO_USER_PASSWORD=
#
#<UDF name="hostname" label="The hostname for the new Linode.">
# HOSTNAME=
#
# <UDF name="UPGRADE" label="Upgrade the system?" oneof="yes,no" default="no" />

source <ssinclude StackScriptID="1">

cat <<EOF > /etc/motd

STACKSCRIPT IS STILL RUNNING

EOF

system_update

IPADDR=$(system_primary_ip)
system_set_hostname $HOSTNAME
system_add_host_entry $IPADDR $FQDN $HOSTNAME

user_add_sudo $SUDO_USER "${SUDO_USER_PASSWORD}"

if [ -d /root/.ssh ]; then    
	if [ "$SUDO_USER" ]; then
	    cp -r /root/.ssh /home/$SUDO_USER && \
	        chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.ssh && \
	        chmod 700 /home/$SUDO_USER/.ssh
	fi
fi

ufw_install
sed -i '/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/d' /etc/ufw/before.rules
sed -i '/-A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT/d' /etc/ufw/before.rules
sed -i '/-A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT/d' /etc/ufw/before.rules
sed -i '/-A ufw-before-input -p udp -d 224.0.0.251 --dport 5353 -j ACCEPT/d' /etc/ufw/before.rules
sed -i '/-A ufw-before-input -p udp -d 239.255.255.250 --dport 1900 -j ACCEPT/d' /etc/ufw/before.rules
sed -i '/-A ufw6-before-input -p icmpv6 --icmpv6-type echo-reply -j ACCEPT/d' /etc/ufw/before6.rules
sed -i '/-A ufw6-before-forward -p icmpv6 --icmpv6-type echo-reply -j ACCEPT/d' /etc/ufw/before6.rules
sed -i '/-A ufw6-before-input -p udp -s fe80::\/10 --sport 547 -d fe80::/10 --dport 546 -j ACCEPT/d' /etc/ufw/before6.rules
sed -i '/-A ufw6-before-input -p udp -d ff02::fb --dport 5353 -j ACCEPT/d' /etc/ufw/before6.rules
sed -i '/-A ufw6-before-input -p udp -d ff02::f --dport 1900 -j ACCEPT/d' /etc/ufw/before6.rules
ufw reload

[ "$UPGRADE" = "yes" ] && {
	debian_upgrade
}

DEBIAN_FRONTEND=noninteractive
apt-get -y install xorg xbacklight xbindkeys xvkbd xinput xserver-xorg-input-all -qq >/dev/null
apt-get -y install openbox obconf menu -qq >/dev/null
apt-get -y install git -qq >/dev/null
apt-get -y install tigervnc-standalone-server screen psmisc gentoo -qq >/dev/null
apt-get -y install dbus-x11 feh hsetroot i3lock libnotify-bin lximage-qt network-manager network-manager-gnome pavucontrol pulseaudio pulseaudio-utils rofi scrot tint2 volumeicon-alsa xfce4-power-manager xfce4-terminal -qq >/dev/null
apt-get -y install adwaita-qt fonts-dejavu fonts-firacode fonts-liberation2 gnome-themes-standard gtk2-engines-murrine gtk2-engines-pixbuf lxappearance obconf papirus-icon-theme qt5-style-plugins -qq >/dev/null
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt -y install ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

mkdir -p /etc/opt/chrome/policies/recommended/
cat <<EOF > /etc/opt/chrome/policies/recommended/recommended_policies.json
{
  "RestoreOnStartup": 1,
  "PromotionalTabsEnabled": false,
  "MetricsReportingEnabled": false,
  "DefaultBrowserSettingEnabled": false
}
EOF

su $SUDO_USER <<EOSU
cd
git clone https://github.com/akda5id/debian_dotfiles.git
cp -r debian_dotfiles/.config ~/
cp debian_dotfiles/.xinitrc ~/.xinitrc
umask 0077
mkdir -p ~/.vnc
vncpasswd -f <<<"password" > ~/.vnc/passwd
vncserver -geometry 1280x720 :1
EOSU


stackscript_cleanup

wall -n "The Stackscript has finished, enjoy."

cat <<EOF > /etc/motd
The Stackscript has finished, enjoy.
EOF