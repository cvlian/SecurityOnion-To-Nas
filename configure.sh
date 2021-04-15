#! /bin/bash

#
# INCLUDES
#
INC="/etc/nsm/administration.conf"
. $INC

. $NSM_LIB_DIR/lib-console-utils
. $NSM_LIB_DIR/lib-nsm-common-utils
. $NSM_LIB_DIR/lib-nsm-sensor-utils

#
# USAGE
#
print_usage()
{
	echo 
	echo "Synology NAS management scripts for storing network traffic data (pcap file)."
	echo 
	echo "Usage: $0 [options]"
	echo
	echo "Options:"
	echo "    --sensor-name=<name>             Define specific sensor <name> to process"
	echo "    --nas-dir=<name>                 Address of NAS shared directory"
	echo "    --shared-dir=<name>              Directory where NAS should be mounted"
	echo
	echo "    --help                           Same as -h"
	echo 
}

# script specific variables
SENSOR_NAME=""
NAS_DIR=""
SHARED_DIR=""

# extract necessary pre-check arguments from the commandline
while [ "$#" -gt 0 ]
do
	case $1 in
		"-h" | "--help")
			print_usage
			exit 1
			;;	
		--sensor-name*)
			SENSOR_NAME="$SENSOR_NAME $(echo $1 | cut -d "=" -f 2)"
			;;
		--nas-dir*)
			NAS_DIR="$NAS_DIR $(echo $1 | cut -d "=" -f 2)"
			;;
		--shared-dir*)
			SHARED_DIR="$SHARED_DIR $(echo $1 | cut -d "=" -f 2)"
			;;
        *)
			echo_error_msg 0 "OOPS: Unknown option \"${1}\" found!"
			print_usage
			exit 1
            ;;
	esac
	shift
done

if [ -z "$SENSOR_NAME" ]; then
	echo_error_msg 0  "Missing '--sensor-name' option!!"
	print_usage
	exit 1
fi

if [ -z "$NAS_DIR" ]; then
	echo_error_msg 0  "Missing '--nas-dir' option!!"
        print_usage
	exit 1
fi

if [ -z "$SHARED_DIR" ]; then
	echo_error_msg 0  "Missing '--shared-dir' option!!"
        print_usage
	exit 1
fi

# ensure we are root user before continuing any further
is_root
if [ "$?" -ne 0 ]
then
	echo_error_msg 0 "OOPS: Must be root to run this script!"
	exit 1
fi

# see if any sensors are disabled or nonexistent
for SENSOR in $SENSOR_NAME; do
	if grep -q -P "#$SENSOR\t" /etc/nsm/sensortab; then
		echo "$SENSOR disabled, exiting."
		exit 1
	fi
	if ! grep -q -P "$SENSOR\t" /etc/nsm/sensortab; then
		echo "$SENSOR not found, exiting."
		exit 1
	fi
done

#
# START
#

# install pre-requisitions
apt-get update

dpkg -s nfs-common &> /dev/null

if [ $? -eq 0 ]; then
	apt-get install nfs-common
fi

# deactivate security-onion services
so-elasticsearch-stop
so-bro-stop
nsm_sensor_ps-stop

if [ ! -d "$SHARED_DIR" ]; then
	mkdir -p $SHARED_DIR
	chown $SENSOR_USER:$SENSOR_GROUP $SHARED_DIR
	chmod 775 $SHARED_DIR
fi

mount -t nfs $NAS_DIR $SHARED_DIR &> /dev/null

if [ $? -eq 0 ]; then
	echo_error_msg 0 "Could not access $NAS_DIR, check the nfs permission"
	exit 1
fi

echo "$NAS_DIR	$SHARED_DIR	nfs	defaults,nofail	0	0" >> /etc/fstab

# change timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# update packet sensor scripts
for f in nsm_sensor_ps*
do
	chmod 755 $f
	chwon root:root $f
	cp $f $NSM_GENERAL_SBIN_DIR
done

nsm_sensor_ps-start --sensor-name=$SENSOR_NAME --nas-dir=$SHARED_DIR

