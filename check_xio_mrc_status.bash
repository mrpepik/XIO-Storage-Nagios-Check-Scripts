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
        echo "Check the XIO Storage System MRC Status and Temperatures."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}

function MRC_Status() {

MRC1Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.1.10.0"
MRC1TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.1.11.0"
MRC1TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.1.12.0"
MRC1PortStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.1.17.0"

MRC2Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.2.10.0"
MRC2TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.2.11.0"
MRC2TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.2.12.0"
MRC2PortStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.3.2.17.0"

MRC1PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC1PortStatus`
MRC2PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC2PortStatus`
MRC1PS=`sed -e 's/^"//' -e 's/"$//' <<<"$MRC1PS"`
MRC2PS=`sed -e 's/^"//' -e 's/"$//' <<<"$MRC2PS"`

if [ $MRC1PS == "Operational" ] && [ $MRC2PS == "Operational" ]
then

        MRC1Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC1Temp`
        MRC1Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC1Temp`
        MRC1Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC1Temp`
        MRC2Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC2Temp`
        MRC2Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC2Temp`
        MRC2Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $MRC2Temp`
        if [ $MRC1Ts -le $MRC1Tw ] && [ $MRC2Ts -le $MRC2Tw ]
        then
                echo "MRC1 and MRC2 Temperatures are below Warning Level set in device.  MRC1Temp: $MRC1Ts,  MRC2Temp: $MRC2Ts"
                exit 0
        elif ( [ $MRC1Ts -gt $MRC1Tw ] && [ $MRC1Ts -le $MRC1Tc ] ) || ( [ $MRC2Ts -gt $MRC2Tw ] && [ $MRC2Ts -le $MRC2Tc ] )
	then
                echo "MRC1 and MRC2 Temperatures are above the Warning Level set in device.  MRC1Temp: $MRC1Ts,  MRC2Temp: $MRC2Ts"
                exit 1
        elif  [ $MRC1Ts -gt $MRC1Tr ] || [ $MRC2Ts -gt $MRC2Tc ]
	then
                echo "MRC1 and MRC2 Temperatures are above the Critical  Level set in device.  MRC1Temp: $MRC1Ts,  MRC2Temp: $MRC2Ts"
                exit 2
        else
                echo "MRC1 and MRC2 Temperatures are Unknown"
                exit 3
        fi
else
        echo "MRC1PortStatus or MRC2PortStatus is Critical: MRC1 = $$MRC1PS. MRC2 = $MRC2PS"
        exit 2
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

MRC_Status


