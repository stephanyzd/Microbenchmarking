#!/bin/bash

# ----------- READ FROM CONFIG FILE 
base=`pwd`
relative="/../CONFIG/jitter_packetloss.config"
source $base$relative

# ----------- PATH OF MEASUREMENTS FILES
JITTER_PACKETLOSS_PATH=$(echo "$base/JITTER_PACKETLOSS_DATA")

if [ ! -d "$JITTER_PACKETLOSS_PATH" ]; then
	`mkdir -p $JITTER_PACKETLOSS_PATH`
fi

# ----------- FUNCTIONS ------------ #

# Assign target domains to arraymap "targetdomains"
function read_target_domains(){
	IFS=,
	arr=($TARGET_DOMAIN_IP)

	for key in "${!arr[@]}"; 
	do 
		IFS== read domainname ipaddress <<< ${arr[$key]}
		targetdomains[$domainname]=$ipaddress
	done
}


function target_domains_status(){
	# iterate through targets domains U
	# - check if it's up
	# - check if it's listening on 5201 port

	for domainid in "${!targetdomains[@]}"; do
	
		domainaddress=${targetdomains[$domainid]}

		# check if domain is up 
		ping -q -c2 $domainaddress > /dev/null
		if [ $? -eq 0 ]; then
			echo "$domainid - $domainaddress is up"
		else
			echo "$domainid - $domainaddress is down"
			shutdowndomain+=($domainid)
		fi
		
		# check if target domains is listening on iperf port :: 5201
		nc -z -q 2 $domainaddress 5201 &> /dev/null
		if [ $? -eq 0 ]; then
			echo "$domainid - $domainaddress is listening on port 5201"
		else
			echo "$domainid - $domainaddress is NOT listening on port 5201"
			dontiperf+=($domainid)
		fi
		echo "################"
	done
}



#----------------------------------- #
# -------------- MAIN -------------- #
#----------------------------------- #


#@function call --- map target domains
read_target_domains
#@function call --- check domains status
target_domains_status


#-------------------------------------- #
#-------------------------------------- #
# QOS METRIC: JITTER MEASUREMENT
#-------------------------------------- #
#-------------------------------------- #
# --- IPERF COMMAND LINE

# -f K  	format message size (KBytes/sec)
# -i  		interval for printing jitter data
# --udp		set UDP as transport protocol
# -c 		set target vm
# -t 		test lenght = overall time spend on this experiment.
# -l 		set packet size (KB)


JITTER_PACKETLOSS_COMMAND=$(iperf3 -u -c 10.0.0.10 -f K -i $INTERIM_DATA -t $EXPERIMENT_TIME -l $PACKET_SIZE --get-server-output)

# if target domain netperf is up, then we execute the command
if [[ ! " ${dontiperf[@]} " =~ " ${domainid} " ]]; then

	# check if output file doesn't exist ... if not, creates it
	if [ ! -f "$JITTER_PACKETLOSS_PATH/$ipaddress.file" ]; then
		`echo -n "" > $JITTER_PACKETLOSS_PATH/$ipaddress.file`
	fi

	# timestamp checkpoint
	INIT_TIMESTAMP=`date  +%Y-%m-%d:%H:%M:%S`

	`echo "--- $INIT_TIMESTAMP --- " >> $JITTER_PACKETLOSS_PATH/$ipaddress.file`

		OUTPUT_COMMAND=$(echo $JITTER_PACKETLOSS_COMMAND)
		
		
		printf '%s\n' "$OUTPUT_COMMAND" | while IFS= read -r line
		do
   			echo "bla $line"
		done


	`echo "$THROUGHPUT_DATA" >> $JITTER_PACKETLOSS_PATH/$ipaddress.file`
	`echo "--- END --- " >>  $JITTER_PACKETLOSS_PATH/$ipaddress.file`
else
	echo "$domainid can't established connection with iperf server"
fi