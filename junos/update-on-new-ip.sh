###
#    Copyright 2017 Zmegolaz <zmegolaz@kaizoku.se>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
###
#    This script monitors your chosen interface for IP changes and updates
#    your configuration to match it. Useful if you have dynamic IP and
#    tunnels or NAT policies where you explicitly have to configure your
#    own IP.
###
#    Put this file somewhere (like /cf/var/db/scripts/) and add it to
#    crontab like this:
#    */15 * * * * /sbin/sh /cf/var/db/scripts/update-on-new-ip.sh
###

# Config.

# Interface we want to monitor for new address.
interface="vlan.300"

# Command to get the old IP. Make sure it doesn't list multiple ones!
oldipcommand="show configuration interfaces ip-0/0/0 unit 0 tunnel source"

# DDNS info, leave it empty if you don't use it.
# Server to send updates to, like "members.dyndns.org" or similar.
ddnsserver="members.dyndns.org"
# FQDN of the hostname to update.
ddnshostname="hostname.example.com"
# Username.
ddnsuser="username"
# Password or update key.
ddnspass="secretpass"

# Config done!

oldip=`echo "$oldipcommand" | /usr/sbin/cli | egrep -o "[0-9\.]{7,}"`
newip=`echo "show interface terse $interface" | /usr/sbin/cli | egrep -o "[0-9\.]{7,}"`

# Something wrong with oldipcommand.
if [ "" = "$oldip" ]; then
        exit 1
fi

# If we don't have any ip, request one and exit. Our next run will take care of updating config.
if [ "" = "$newip" ]; then
        echo "request dhcp client renew interface $interface" | /usr/sbin/cli
        exit 0
fi

# Exit if we haven't changed IP.
if [ "$oldip" = "$newip" ]; then
        exit 0
fi

# Do the actual config update.
echo "configure private
replace pattern $oldip with $newip
commit comment \"replaced $oldip with $newip\" and-quit
exit" | /usr/sbin/cli

# Update DDNS if it's configured.
if [ "" != "$ddnsserver" ] && [ "" != "$ddnshostname" ] && [ "" != "$ddnsuser" ] && [ "" != "$ddnspass" ]; then
        fetch-secure -o /dev/null "https://$ddnsuser:$ddnspass@$ddnsserver/nic/update?hostname=$ddnshostname&myip=$newi
p"
fi

