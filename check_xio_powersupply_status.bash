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
        echo "Check the XIO Storage System Power Supply Status, Fan Status, and Fan Temperatures."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}


function PowerSupply_Status() {

powerSupply1SerialNum="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.1.0"
powerSupply1PartNum="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.2.0"
powerSupply1Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.4.0"
powerSupply1StatusDetails="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.5.0"
powerSupply1Temperature="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.6.0"
powerSupply1TempThreshWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.7.0"
powerSupply1TempThreshCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.8.0"
powerSupply1Position="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.9.0"
powerSupply1FanStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.10.0"
powerSupply1FanSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.11.0"
powerSupply1FanDesiredSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.12.0"
powerSupply1StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.13.0"
powerSupply1StatusDetailsStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.14.0"
powerSupply1FanStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.15.0"
powerSupply1Fan2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.16.0"
powerSupply1Fan2Speed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.17.0"
powerSupply1Fan2DesiredSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.18.0"
powerSupply1Fan2StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.1.19.0"
	
powerSupply2SerialNum="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.1.0"
powerSupply2PartNum="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.2.0"
powerSupply2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.4.0"
powerSupply2StatusDetails="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.5.0"
powerSupply2Temperature="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.6.0"
powerSupply2TempThreshWarn="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.7.0"
powerSupply2TempThreshCrit="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.8.0"
powerSupply2Position="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.9.0"
powerSupply2FanStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.10.0"
powerSupply2FanSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.11.0"
powerSupply2FanDesiredSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.12.0"
powerSupply2StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.13.0"
powerSupply2StatusDetailsStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.14.0"
powerSupply2FanStatus="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.15.0"
powerSupply2Fan2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.16.0"
powerSupply2Fan2Speed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.17.0"
powerSupply2Fan2DesiredSpeed="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.18.0"
powerSupply2Fan2StatusStr="SNMPv2-SMI::enterprises.2366.6.1.2.1.6.2.19.0"


PS1S=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply1StatusStr`
PS2S=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply2StatusStr`

PS1S=`sed -e 's/^"//' -e 's/"$//' <<<"$PS1S"`
PS2S=`sed -e 's/^"//' -e 's/"$//' <<<"$PS2S"`

if [ $PS1S == "Operational" ] && [ $PS2S == "Operational" ]
then
        dps="OK - Power Supply 1 and Power Supply 2 are Operational"
        dpsc=0
		
        powerSupply1Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply1Temperature`
        powerSupply1Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply1TempThreshWarn`
        powerSupply1Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply1TempThreshCrit`
        powerSupply2Ts=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply2Temperature`
        powerSupply2Tw=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply2TempThreshWarn`
        powerSupply2Tc=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply2TempThreshCrit`
        powerSupply1FanStatus=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply1Fan2StatusStr`
        powerSupply2FanStatus=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $powerSupply2Fan2StatusStr`

	powerSupply1FanStatus=`sed -e 's/^"//' -e 's/"$//' <<<"$powerSupply1FanStatus"`
	powerSupply2FanStatus=`sed -e 's/^"//' -e 's/"$//' <<<"$powerSupply2FanStatus"`


        if [ $powerSupply1FanStatus == "Operational" ] && [ $powerSupply2FanStatus == "Operational" ]
		then
			PSF="OK - Power Supply 1 Fan and Power Supply 2 Fan are Operational"
			PSFc=0
		else
			PSF="CRITICAL - Power Supply 1 Fan or Power Supply 2 Fan has errors: powerSupply1Fan: $powerSupply1FanStatus, powerSupply2Fan: $powerSupply2FanStatus "
			PSFc=2
		fi
		
        if [ $powerSupply1Ts -le $powerSupply1Tw ] && [ $powerSupply2Ts -le $powerSupply2Tw ]
        then
                ts="OK - powerSupply1 or powerSupply2 Temperatures are below Warning Level set in device.  powerSupply1Temp: $powerSupply1Ts,  powerSupply2Temp: $powerSupply2Ts"
                tsc=0
        elif  ( [ $powerSupply1Ts -gt $powerSupply1Tw ] && [ $powerSupply1Ts -le $powerSupply1Tc ] ) || ( [ $powerSupply2Ts -gt $powerSupply2Tw ] && [ $powerSupply2Ts -le $powerSupply2Tc ] )
	then
                ts="WARNING - powerSupply1 or powerSupply2 Temperatures are above the Warning Level set in device.  powerSupply1Temp: $powerSupply1Ts,  powerSupply2Temp: $powerSupply2Ts"
                tsc=1
        elif  [ $powerSupply1Ts -gt $powerSupply1Tw ]] || [ $powerSupply2Ts -gt $powerSupply2Tc ]
	then
                ts="CRITICAL - powerSupply1 or powerSupply2 Temperatures are above the Critical  Level set in device.  powerSupply1Temp: $powerSupply1Ts,  powerSupply2Temp: $powerSupply2Ts"
                tsc=2
        else
                ts="UNKNOWN - powerSupply1 or powerSupply2 Temperatures are Unknown"
                tsc=3
        fi

else
        dps="CRITICAL - powerSupply1 or powerSupply2 is Critical: powerSupply1 = $$PS1S. powerSupply2 = $PS2S"
        dpsc=2
fi
if [ $dpsc -gt 0 ]
then
echo "$dps; $PSF; $ts"
        exit $dpsc
elif [ $PSFc -gt 0 ]
then
echo "$PSF; $dps; $ts"
        exit $PSFc
elif [ $tsc -gt 0 ]
then
echo "$ts; $dps; $PSF"
        exit $tsc
else
echo "$dps; $PSF; $ts"
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

PowerSupply_Status


