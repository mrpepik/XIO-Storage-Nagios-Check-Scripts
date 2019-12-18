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
        echo "Check the XIO Storage System DataPac Status, Number of Bad Drives, and Temperatures."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}

function DataPac_Status() {

DP1Capacity="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.8.0"
DP1Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.10.0"
DP1TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.11.0"
DP1TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.12.0"
DP1PortStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.13.0"
DP1NumBadDrives="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.15.0"
DP1Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.1.16.0"

DP2Capacity="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.8.0"
DP2Temp="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.10.0"
DP2TempWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.11.0"
DP2TempCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.12.0"
DP2PortStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.17.0"
DP2NumBadDrives="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.15.0"
DP2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.4.2.16.0"

DP1PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP1Status`
DP2PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP2Status`

DP1PS=`sed -e 's/^"//' -e 's/"$//' <<<"$DP1PS"`
DP2PS=`sed -e 's/^"//' -e 's/"$//' <<<"$DP2PS"`

if [ $DP1PS == "Operational" ] && [ $DP2PS == "Operational" ]
then
        dps="OK - P1PortStatus and DP2PortStatus are Operational"
        dpsc=0
        DP1NBD=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP1NumBadDrives`
        DP2NBD=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP2NumBadDrives`
        DP1Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP1Temp`
        DP1Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP1TempWarn`
        DP1Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP1TempCrit`
        DP2Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP2Temp`
        DP2Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP2TempWarn`
        DP2Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $DP2TempCrit`

        if [[ $DP1NBD == 0 ]] && [[ $DP2NBD == 0 ]]
        then
                bd="OK:  No Bad Disks Found on Data Pacs"
                bdc=0
        else
                bd="CRITICAL:  Found Bad Disks Reported By DataPac:  dataPac1 number of Bad Disks = $DP1NBD, dataPac2 number of Bad Disks = $DP2NBD"
                bdc=2
        fi

        if [ $DP1Ts -le $DP1Tw ] && [ $DP2Ts -le $DP2Tw ]
        then
                ts="OK - DP1 or DP2 Temperatures are below Warning Level set in device.  DP1Temp: $DP1Ts,  DP2Temp: $DP2Ts"
                tsc=0
        elif  ( [ $DP1Ts -gt $DP1Tw ] && [ $DP1Ts -le $DP1Tc ] ) || ( [ $DP2Ts -gt $DP2Tw ] && [ $DP2Ts -le $DP2Tc ] )
	then
                ts="WARNING - DP1 or DP2 Temperatures are above the Warning Level set in device.  DP1Temp: $DP1Ts,  DP2Temp: $DP2Ts"
                tsc=1
        elif  [ $DP1Ts -gt $DP1Tw ]] || [ $DP2Ts -gt $DP2Tc ]
	then
                ts="CRITICAL - DP1 or DP2 Temperatures are above the Critical  Level set in device.  DP1Temp: $DP1Ts,  DP2Temp: $DP2Ts"
                tsc=2
        else
                ts="UNKNOWN - DP1 or DP2 Temperatures are Unknown"
                tsc=3
        fi
else
        dps="CRITICAL - DP1PortStatus or DP2PortStatus is Critical: DP1 = $$DP1PS. DP2 = $DP2PS"
        dpsc=2
fi
if [ $dpsc -gt 0 ]
then
echo "$dps; $bd; $ts"
        exit $dpsc
elif [ $bdc -gt 0 ]
then
echo "$bd; $dps; $ts"
        exit $bdc
elif [ $tsc -gt 0 ]
then
echo "$ts; $bds; $bd"
        exit $tsc
else
echo "$dps; $bd; $ts"
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

DataPac_Status


