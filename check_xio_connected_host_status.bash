#!/usr/bin/bash
#    Copyright (C) 2019 - Joseph Hardeman <jwhardeman@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation version 3 of the License
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


# --------------------------------------------------------------------
# configuration
# --------------------------------------------------------------------
PROGNAME=$(basename $0)
ERR_MESG=()
LOGGER="`which logger` -i -p kern.warn -t"

AUTO=0
AUTOIGNORE=0
IGNOREFSTAB=0
WRITETEST=0

export PATH="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin:/usr/sfw/bin"
LIBEXEC="/opt/nagios/libexec /usr/lib64/nagios/plugins /usr/lib/nagios/plugins /usr/local/nagios/libexec /usr/local/icinga/libexec /usr/local/libexec /opt/csw/libexec/nagios-plugins"
for i in ${LIBEXEC} ; do
  [ -r ${i}/utils.sh ] && . ${i}/utils.sh
done

if [ -z "$STATE_OK" ]; then
  echo "nagios utils.sh not found" &>/dev/stderr
  exit 1
fi

# --------------------------------------------------------------------
# functions
# --------------------------------------------------------------------
function log() {
        $LOGGER ${PROGNAME} "$@";
}

function usage() {
        echo -e "Usage: $PROGNAME [-H HOSTNAME] -v [snmp version] -C [Community String]"
        echo "Usage: $PROGNAME -h,--help"
        echo "Options:"
        echo " -H          Hostname or IP of XIO Storage Device"
        echo " -v          SNMP version (default: 2c)"
        echo " -C          SNMP Community String (default: public)"
}

function print_help() {
        echo ""
        usage
        echo ""
        echo "Check the status of the XIO Storage Unit Connected Hosts."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}


function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}


function ConnectedHost_status() {
#Need to take this number and loop thru to pull stats
iseTotalHosts="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.34.0"

TotalHosts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $iseTotalHosts`

oidnumber=1
totalhostcount=$TotalHosts
declare -a dpsc
declare -a info
declare -a cdc

for i in `seq $totalhostcount`
do

	# Stating at NMPv2-SMI::enterprises.2366.6.1.2.1.9.1 start counting up till you reach the total number of hosts connected
	Name="SNMPv2-SMI::enterprises.2366.6.1.2.1.9.${oidnumber}.1.0"
	Os="SNMPv2-SMI::enterprises.2366.6.1.2.1.9.${oidnumber}.2.0"
	Id="SNMPv2-SMI::enterprises.2366.6.1.2.1.9.${oidnumber}.3.0"
	StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.9.${oidnumber}.4.0"
	StatusDetailsStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.9.${oidnumber}.5.0"


	hoststatus=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $StatusStr`
	hostname=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $Name`

	hoststatus=`sed -e 's/^"//' -e 's/"$//' <<<"$hoststatus"`

	if [ $hoststatus == "Operational" ]
	then
			info[$oidnumber]="OK - Host $hostname: $hoststatus, "
			dpsc[$oidnumber]="0"

	else
			info[$oidnumber]="CRITICAL - Host $hostname: $hoststatus, "
			dpsc[$oidnumber]="2"
fi
	let oidnumber=$oidnumber+1
done

echo "${info[@]}"

if [ $(contains "${dpsc[@]}" "2") == "y" ]
then
        exit 2
else
        exit 0
fi
}



# --------------------------------------------------------------------
# startup checks
# --------------------------------------------------------------------

if [ $# -eq 0 ]; then
        usage
        exit $STATE_CRITICAL
fi

# --------------------------------------------------------------------
# Default States

# --------------------------------------------------------------------
SNMP_VERSION="2c"
COMMUNITY="public"

# --------------------------------------------------------------------
# pull in variables
# --------------------------------------------------------------------
while [ "$1" != "" ]
do
        case "$1" in
                --help) print_help; exit $STATE_OK;;
                -h) print_help; exit $STATE_OK;;
                -H) HOSTNAME=$2; shift 2;;
                -v) SNMP_VERSION=$2; shift 2;;
                -C) COMMUNITY=$2; shift 2;;
                *) usage; exit $STATE_UNKNOWN;;
        esac
done


#
#

ConnectedHost_status


