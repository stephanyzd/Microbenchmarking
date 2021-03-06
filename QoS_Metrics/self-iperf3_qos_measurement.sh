#!/bin/bash



declare -A targetdomains

# ----------- READ FROM CONFIG FILE 
base=`pwd`
relative="/../CONFIG/throughput_jitter_packetloss.config"
source $base$relative

# ----------- PATH OF MEASUREMENTS FILES
JITTER_PATH=$(echo "$base/JITTER_DATA")
PACKET_LOSS_PATH=$(echo "$base/PACKET_LOSS_DATA")
THROUGHPUT_PATH=$(echo "$base/THROUGHPUT_DATA")
BANDWIDTH_PATH=$(echo "$base/BANDWIDTH_DATA")


if [ ! -d "$JITTER_PATH" ]; then
	`mkdir -p $JITTER_PATH`
fi

if [ ! -d "$PACKET_LOSS_PATH" ]; then
	`mkdir -p $PACKET_LOSS_PATH`
fi

if [ ! -d "$THROUGHPUT_PATH" ]; then
	`mkdir -p $THROUGHPUT_PATH`
fi

if [ ! -d "$BANDWIDTH_PATH" ]; then
	`mkdir -p $BANDWIDTH_PATH`
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


#----------------------------------- #
# -------------- MAIN -------------- #
#----------------------------------- #


#@function call --- map target domains
read_target_domains


#-------------------------------------- #
#-------------------------------------- #
# QOS METRIC: THROUGHPUT MEASUREMENT
# QOS METRIC: JITTER MEASUREMENT
# QOS METRIC: PACKET LOSS MEASUREMENT
#-------------------------------------- #
#-------------------------------------- #
# --- IPERF COMMAND LINE

# -f K  	format message size (KBytes/sec)
# -i  		interval for printing jitter data
# --udp		set UDP as transport protocol
# -c 		set target vm
# -t 		test lenght = overall time spend on this experiment.
# -l 		set packet size (KB)
# -b=0		prevent bandwidth from being limited


QOS_MEASUREMENT_COMMAND=$(iperf3 -u -c 10.0.0.2 -b 160M -i $INTERIM_DATA -t $EXPERIMENT_TIME -l $PACKET_SIZE --get-server-output)


	# timestamp checkpoint
	INIT_TIMESTAMP=`date  +%Y-%m-%d:%H:%M:%S`

	`echo "--- $domainid --- $INIT_TIMESTAMP --- " >> $PACKET_LOSS_PATH/$ipaddress.file`
	`echo "--- $domainid --- $INIT_TIMESTAMP --- " >> $JITTER_PATH/$ipaddress.file`
	`echo "--- $domainid --- $INIT_TIMESTAMP --- " >> $THROUGHPUT_PATH/$ipaddress.file`
	`echo "--- $domainid --- $INIT_TIMESTAMP --- " >> $BANDWIDTH_PATH/$ipaddress.file`

		OUTPUT_COMMAND=$(echo $QOS_MEASUREMENT_COMMAND)
		echo $OUTPUT_COMMAND	

		# --------------
		# THROUGHPUT
		# --------------
		# JITTER
		# --------------
		# PACKET LOSS
		# --------------
		# BANDWIDTH
		# --------------

		# string manipulation
		OUTPUT_1=$(echo "${OUTPUT_COMMAND##*Server output}")
		OUTPUT_2=$(echo "$OUTPUT_1" | sed '1,5d' | head -n -1)
		#throughput (mb/s)
		THROUGHPUT=$(echo "$OUTPUT_2" | awk -F" " '{print $5}')
		#bandwidth (mb/s)
		BANDWIDTH=$(echo "$OUTPUT_2" | awk -F" " '{print $7}')
		# jitter (ms)
		JITTER=$(echo "$OUTPUT_2" | awk -F" " '{print $9}')
		# packet loss (%)
		PACKET_LOSS=$(echo "$OUTPUT_2" | awk -F" " '{print $11}')
		
		`echo "$THROUGHPUT" >> $THROUGHPUT_PATH/$ipaddress.file`
		`echo "$JITTER" >> $JITTER_PATH/$ipaddress.file`
		`echo "$PACKET_LOSS" >> $PACKET_LOSS_PATH/$ipaddress.file`
		`echo "$BANDWIDTH" >> $BANDWIDTH_PATH/$ipaddress.file`


	`echo "--- END --- " >>  $PACKET_LOSS_PATH/$ipaddress.file`
	`echo "--- END --- " >>  $JITTER_PATH/$ipaddress.file`
	`echo "--- END --- " >>  $THROUGHPUT_PATH/$ipaddress.file`
	`echo "--- END --- " >>  $BANDWIDTH_PATH/$ipaddress.file`
