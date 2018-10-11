#!/bin/bash
# UpdateAMI.sh
# Script to automate the updating of software on each AMI

# Assumptions:
# 1) You have an "AMI instance" instance that you update with software changes, config changes, etc.
# 2) This instance follows the naming convention of "name-ami"
 
# Methodology:
# 1) Update the "AMI instance" with your changes (here, that is copying new software over to the instance which is done in a separate script)
# 2) Deregister the actual AMI of the given name to make way for the updated AMI
# 3) Create an AMI from your "AMI instance"

# Set up variables
AWS_DEFAULT_REGION="us-east-1"
AWS_DEFAULT_OUTPUT="text"
REG="us-east-1"

# Show the user how to use the script
function printHelp {
    echo "[INFO] Usage instructions:"
    echo "[INFO] ./UpdateAMI.sh <AMI name>;"
    echo "[INFO] example: ./UpdateAMI.sh dev-machine;"
}

# Validate user input to this script
function validateInputParameters {
    if [ -z ${1+x} ]; then 
        echo "[ERROR] Expected an AMI name as the first argument."
        printHelp
        exit
    else 
	# Set the AMI  name
        AMI_NAME=$1
    fi
}

# Function to deregister an AMI based on AMI ID
deregister_AMI(){
	echo "[INFO] Deregistering old AMI..."

	# Use the ROUGH_ID to store the image ID in its raw JSON form
	ROUGH_ID="$(aws ec2 describe-images --filters "Name=name, Values=$AMI_NAME" --region $REG --query 'Images[*].{ID:ImageId}')"

	# Take the ROUGH_ID and extract just the actual ID and store it 
	AMI_ID="$(echo $ROUGH_ID | grep -o -P '(?<=: ").*(?=")')"
	
	# If the AMI ID exists
	if [ "${#AMI_ID}" -gt 0 ]
        then
		echo "[INFO] AMI ID for $AMI_NAME is: $AMI_ID"
		# Deregister the image
		echo "[INFO] Removing AMI with Name: $AMI_NAME and ID: $AMI_ID"
		aws ec2 deregister-image --image-id $AMI_ID --region $REG
	else
		echo "[ERROR] The AMI with Name: $AMI_NAME does not exist"
	fi
}

# Function to create a new AMI from the AMI Instance
create_AMI(){
	echo "[INFO] Creating new AMI from updated AMI instance..."	

	# Use the name plus "-ami" to get the AMI Instance ID
	INSTANCE_ID="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$AMI_NAME-ami" --output text --region $REG --query 'Reservations[*].Instances[*].InstanceId')"
	
	if [ "${#INSTANCE_ID}" -gt 0 ]
	then
		# Create a new AMI based on the Instance ID
		echo "[INFO] Creating AMI from instance with ID of $INSTANCE_ID"
		aws ec2 create-image --instance-id $INSTANCE_ID --name $AMI_NAME --description $AMI_NAME --region $REG
	else
		echo "[ERROR] Could not find instance with ID of $INSTANCE_ID"
	fi
}

validateInputParameters ${@}
deregister_AMI
create_AMI
