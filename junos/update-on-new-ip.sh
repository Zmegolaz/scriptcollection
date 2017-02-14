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

# Config.

interface="vlan.300"

# Config done!

oldip=`cat /var/tmp/lastip`
newip=`/usr/sbin/cli show interface terse $interface | egrep -o "[0-9\.]{7,}"`

# Exit if we haven't changed IP.
if [ $oldip = $newip ]; then
        exit 0
fi

# First run after boot.
if ["" = $oldip ]; then
        echo $newip > /var/tmp/lastip
        exit 0
fi

# If we don't have any ip, request one and exit. Our next run will take care of updating config and files.
if [ "" = $newip ]; then
        echo "request dhcp client renew interface $interface" | /usr/sbin/cli
        exit 0
fi

echo "configure private
replace pattern $oldip with $newip
commit comment \"replaced $oldip with $newip\" and-quit
exit" | /usr/sbin/cli

echo $newip > /var/tmp/lastip

