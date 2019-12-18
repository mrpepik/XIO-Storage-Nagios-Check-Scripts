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
        echo "Check the XIO Storage System SuperCap Status and Temperatures."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}

function SuperCap_Status() {

superCap1Capacity="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.1.6.0"
superCap1Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.1.7.0"
superCap1TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.1.8.0"
superCap1TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.1.9.0"
superCap1Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.1.10.0"

superCap2Capacity="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.2.6.0"
superCap2Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.2.7.0"
superCap2TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.2.8.0"
superCap2TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.2.9.0"
superCap2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.7.2.10.0"

superCap1PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap1Status`
superCap2PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap2Status`

superCap1PS=`sed -e 's/^"//' -e 's/"$//' <<<"$superCap1PS"`
superCap2PS=`sed -e 's/^"//' -e 's/"$//' <<<"$superCap2PS"`

if [ $superCap1PS == "Operational" ] && [ $superCap2PS == "Operational" ]
then
        superCaps="OK - P1PortStatus and superCap2PortStatus are Operational"
        superCapsc=0

        superCap1Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap1Temp`
        superCap1Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap1TempWarn`
        superCap1Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap1TempCrit`
        superCap2Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap2Temp`
        superCap2Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap2TempWarn`
        superCap2Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $superCap2TempCrit`


        if [ $superCap1Ts -le $superCap1Tw ] && [ $superCap2Ts -le $superCap2Tw ]
        then
                ts="OK - superCap1 or superCap2 Temperatures are below Warning Level set in device.  superCap1Temp: $superCap1Ts,  superCap2Temp: $superCap2Ts"
                tsc=0
        elif  ( [ $superCap1Ts -gt $superCap1Tw ] && [ $superCap1Ts -le $superCap1Tc ] ) || ( [ $superCap2Ts -gt $superCap2Tw ] && [ $superCap2Ts -le $superCap2Tc ] )
	then
                ts="WARNING - superCap1 or superCap2 Temperatures are above the Warning Level set in device.  superCap1Temp: $superCap1Ts,  superCap2Temp: $superCap2Ts"
                tsc=1
        elif  [ $superCap1Ts -gt $superCap1Tw ]] || [ $superCap2Ts -gt $superCap2Tc ]
	then
                ts="CRITICAL - superCap1 or superCap2 Temperatures are above the Critical  Level set in device.  superCap1Temp: $superCap1Ts,  superCap2Temp: $superCap2Ts"
                tsc=2
        else
                ts="UNKNOWN - superCap1 or superCap2 Temperatures are Unknown"
                tsc=3
        fi
else
        superCaps="CRITICAL - superCap1PortStatus or superCap2PortStatus is Critical: superCap1 = $$superCap1PS. superCap2 = $superCap2PS"
        superCapsc=2
fi
if [ $superCapsc -gt 0 ]
then
echo "$superCaps; $ts"
        exit $superCapsc
elif [ $tsc -gt 0 ]
then
echo "$ts; $superCaps"
        exit $bdc
else
echo "$superCaps; $ts"
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

SuperCap_Status


