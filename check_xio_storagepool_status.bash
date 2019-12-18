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
        echo -e "Usage: $PROGNAME [-H HOSTNAME] -v [snmp version] -C [Community String] -w 80 (Default=80) -c 90 (Default=90)"
        echo "Usage: $PROGNAME -h,--help"
        echo "Options:"
        echo " -H          Hostname or IP of XIO Storage Device"
        echo " -v          SNMP version (default: 2c)"
        echo " -C          SNMP Community String (default: public)"
        echo " -w          Warning Level, default is set to 80"
        echo " -c          Critical Leve, defualt is set to 90"
}

function print_help() {
        echo ""
        usage
        echo ""
        echo "Check the XIO Storage Unit Free Space and Storage Pool Status."
        echo ""
        echo "This plugin is NOT developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about."
        echo ""
        echo "For contact info, read the plugin itself..."
}

# --------------------------------------------------------------------
# Default States

# --------------------------------------------------------------------
SNMP_VERSION="2c"
COMMUNITY="public"
FSWarn=80
FSCrit=90

function StoragePool_Status() {
SP1Id="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.1.0"
SP1DataPacUsage="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.2.0"
SP1Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.3.0"
SP1TotalAvailableSpace="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.4.0"
SP1TotalManagedSpace="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.5.0"
SP1MaxSizeRaid0="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.6.0"
SP1MaxSizeRaid1="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.7.0"
SP1MaxSizeRaid5="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.8.0"
SP1TotalVolumes="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.10.0"
SP1Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.1.11.0"

SP2Id="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.1.0"
SP2DataPacUsage="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.2.0"
SP2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.3.0"
SP2TotalAvailableSpace="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.4.0"
SP2TotalManagedSpace="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.5.0"
SP2MaxSizeRaid0="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.6.0"
SP2MaxSizeRaid1="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.7.0"
SP2MaxSizeRaid5="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.8.0"
SP2TotalVolumes="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.10.0"
SP2Status="SNMPv2-SMI::enterprises.2366.6.1.2.1.5.2.11.0"

SP1PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP1Status`
SP2PS=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP2Status`

SP1PS=`sed -e 's/^"//' -e 's/"$//' <<<"$SP1PS"`
SP2PS=`sed -e 's/^"//' -e 's/"$//' <<<"$SP2PS"`

if ( [ $SP1PS == "Operational" ]|| [ $SP1PS == "Uninitialized" ] ) && ( [ $SP2PS == "Operational" ] || [ $SP2PS == "Uninitialized" ] )
then
        dps="OK - storagePool1 and storagePool2 are Operational"
        dpsc=0

        if [ $SP1PS == "Operational" ]
        then
                SP1TotalAvailableSpace=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP1TotalAvailableSpace`
                SP1TotalManagedSpace=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP1TotalManagedSpace`
                SP1FSd=`echo "scale=2; $SP1TotalAvailableSpace*100/$SP1TotalManagedSpace" | bc`
                SP1FSnd=`echo "scale=0; $SP1TotalAvailableSpace*100/$SP1TotalManagedSpace" | bc`
                if [ $SP1FSnd -le $FSWarn ]
                then
                        SP1out="OK - Storage Pool 1: $SP1FSd"
                        SP1outc=0
                elif [ $SP1FSnd -gt $FSWarn ] && [ $SP1FSnd -le $FSCrit ]
                then
                        SP1out="WARNING - Storage Pool 1: $SP1FSd"
                        SP1outc=1
                elif [ $SP1FSnd -gt $FSCrit ]
                then
                        SP1out="CRITICAL - Storage Pool 1: $SP1FSd"
                        SP1outc=2
                else
                        SP1out="UNKNOWN - Storage Pool 1: $SP1FSd"
                        SP1outc=3
                fi
        fi

        if [ $SP1PS == "Uninitialized" ]
        then
                SP1out="OK - Storage Pool 2: $SP2FSd"
                SP1outc=0
        fi

        if [ $SP2PS == "Operational" ]
        then
                SP2TotalAvailableSpace=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP2TotalAvailableSpace`
                SP2TotalManagedSpace=`snmpget -Oqv -v $SNMP_VERSION -c $COMMUNITY $HOSTNAME $SP2TotalManagedSpace`
                SP2FSd=`echo "scale=2; $SP2TotalAvailableSpace*100/$SP2TotalManagedSpace" | bc`
                SP2FSnd=`echo "scale=0; $SP2TotalAvailableSpace*100/$SP2TotalManagedSpace" | bc`
                if [ $SP2FSnd -le $FSWarn ]
                then
                        SP2out="OK - Storage Pool 2: $SP2FSd"
            SP2outc=0
                elif [ $SP2FSnd -gt $FSWarn ] && [ $SP2FSnd -le $FSCrit ]
                then
                        SP2out="WARNING - Storage Pool 2: $SP2FSd"
            SP2outc=1
                elif [ $SP2FSnd -gt $FSCrit ]
                then
                        SP2out="CRITICAL - Storage Pool 2: $SP2FSd"
            SP2outc=2
                else
                        SP2out="UNKNOWN - Storage Pool 1: $SP2FSd"
            SP2outc=3
                fi
        fi

        if [ $SP2PS == "Uninitialized" ]
        then
		SP2out="OK - Storage Pool 2: $SP2FSd"
       		SP2outc=0
        fi


else
        dps="CRITICAL - storagePool1 and storagePool2 Critical: StoragePool1 = $$SP1PS. StoragePool2 = $SP2PS"
        dpsc=2
fi
if [ $dpsc -gt 0 ]
then
echo "$dps; $SP1out; $SP2out"
        exit $dpsc
elif [ $SP1outc -gt 0 ]
then
echo "$SP1out; $dps; $SP2out"
        exit $SP1outc
elif [ $SP2outc -gt 0 ]
then
echo "$SP2out; $dps; $SP1out"
        exit $SP2outc
else
echo "$dps; $SP1out; $SP2out"
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
                -w) FSWarn=$2; shift 2;;
                -c) FSCrit=$2; shift 2;;
                *) usage; exit $STATE_UNKNOWN;;
        esac
done


#
#

StoragePool_Status


