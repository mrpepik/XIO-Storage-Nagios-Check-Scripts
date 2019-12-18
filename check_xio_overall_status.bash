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
        echo "Check the XIO Storage General Overal Status."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}


function Overall_Status() {

ISENAME="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.7.0"
ISETEMPERATURE="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.32.0"
ISETOTALVOLUMES="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.33.0"
ISETOTALHOSTS="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.34.0"
ISESTATUS="SNMPv2-SMI::enterprises.2366.6.1.2.1.2.35.0"

NA=ME`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $ISENAME`
TMP=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $ISETEMPERATURE`
TV=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $ISETOTALVOLUMES`
TH=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $ISETOTALHOSTS`
ST=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $ISESTATUS`

ST=`sed -e 's/^"//' -e 's/"$//' <<<"$ST"`

if [ $ST == "Operational" ]
then
        echo "OK - $NA:  Chassis Temperature=$TMP, Total Volumes=$TV, Total Connected Hosts=$TH, Chassis overal Status is $ST"
        exit 0
else
        echo "CRITICAL - $NA:  Chassis Temperature=$TMP, Total Volumes=$TV, Total Connected Hosts=$TH, Chassis overal Status is $ST"
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


Overall_Status


