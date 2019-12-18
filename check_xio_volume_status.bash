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
        echo "Check the Volume Status on the XIO Storage System."
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


function Volume_Status() {

iseTotalVolumes="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.33.0"

TotalVolumes=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $iseTotalVolumes`

oidnumber=16
totalvolumecount=$TotalVolumes
declare -a dpsc
declare -a info
declare -a cdc

for i in `seq $totalvolumecount`
do

	Name="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.1.0"
	VpdId="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.2.0"
	DetailedStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.3.0"
	Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.4.0"
	Id="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.5.0"
	RaidType="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.6.0"
	Pool="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.7.0"
	AllocationType="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.8.0"
	CacheType="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.9.0"
	Size="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.10.0"
	StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.11.0"
	StatusDetailsStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.12.0"
	IsSnapshot="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.13.0"
	SnapshotChildId="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.14.0"
	SnapshotParentId="SNMPv2-SMI::enterprises.2366.6.1.2.1.8.${oidnumber}.15.0"

	volstatus=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $StatusStr`
	volumename=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $Name`

	volstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$volstatus"`

	if [ $volstatus == "Operational" ]
	then
			
			info[$oidnumber]="OK - Volume $volumename: $volstatus, "
			dpsc[$oidnumber]="0"

	else
			info[$oidnumber]="CRITICAL - Volume $volumename: $volstatus, "
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

Volume_Status


