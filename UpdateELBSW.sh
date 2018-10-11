#!/bin/bash

# UpdateELBSW.sh 
# Script to update software on all machines behind an elastic load balancer in AWS

# Set up variables
AWS_DEFAULT_REGION="us-east-1"
AWS_DEFAULT_OUTPUT="text"
REG="us-east-1"
OPTS="-v -i /home/ec2-user/keypair -o StrictHostKeyChecking=no"
USER="ec2-user"

# Show the user how to use the script
function printHelp {
    echo "[INFO] Usage instructions:"
    echo "[INFO] ./UpdateELBSW.sh <ELB name> <Source path> <Destination path>;"
    echo "[INFO] example: ./UpdateELBSW.sh test-machine ~/folder/file.txt /tmp;"
}

# Validate user input to this script
function validateInputParameters {
    if [ $# -ne 3 ]; then
        echo "[ERROR] Expected a load balancer name, source path, and destination path as arguments."
        printHelp
        exit
    else
        # Set the load balancer name
        LB=$1
	# Set the source of the file to be copied
	SRC=$2
	# Set the destination to which the files will be copied
	DEST=$3
    fi
}

# Copy files to each machine behind the ELB
function copyToLBedMachines {
	echo "[INFO] Querying for InstanceIds for ELB $LB..."
	IDs="$(aws elb describe-instance-health --load-balancer-name $LB --query InstanceStates[*].InstanceId --output text --region $REG)"
	IDs=$(echo $IDs | awk '$1=$1')
	echo "[INFO] Retrieved InstanceIds:  $IDs"
	for ID in $IDs; do
  		echo "[INFO] Querying for PrivateIpAddress for InstanceId $ID..."
  		IP="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region $REG)"
  		echo "[INFO] Retrieved PrivateIpAddress for InstanceId $ID:  $IP"
  		echo "[INFO] Copying $SRC to $IP:$DEST"
  		scp $OPTS $SRC $USER@$IP:$DEST
  		echo "[INFO] Updating $DEST on $IP"
	done
}

validateInputParameters ${@}
copyToLBedMachines
