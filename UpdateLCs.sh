#!/bin/bash
# UpdateLCs.sh 
# Script to remove launch config from ASG, delete to launch config, 
# create a new launch config with your new AMI,
# and point the ASG at the new launch config 

# Assumes that you want the settings to be indentical to a launch config
# that you already have in place

AWS_DEFAULT_REGION="us-east-1"
AWS_DEFAULT_OUTPUT="text"
REG="us-east-1"

# Show the user how to use the script
function printHelp {
    echo "[INFO] Usage instructions:"
    echo "[INFO] ./UpdateLCs.sh <LC name>;"
    echo "[INFO] example: ./UpdateLCs.sh test-machine;"
}

# Validate user input to this script
function validateInputParameters {
    if [ $# -ne 1 ]; then
        echo "[ERROR] Expected a launch configuration name."
        printHelp
        exit
    else
        # Set the launch configuration name
        LC=$1
    fi
}

# Get the IAM role setting of the current launch config to use for the new one
function getIAMRole {
	IAM_ROLE="$(aws autoscaling describe-launch-configurations --launch-configuration-names $LC --region $REG --query LaunchConfigurations[*].[IamInstanceProfile] --output text)"
	echo "IAM ROLE is: $IAM_ROLE"
}

# Get the key name setting of the current launch config to use for the new one
function getKeyName {
	KEY_NAME="$(aws autoscaling describe-launch-configurations --launch-configuration-names $LC --region $REG --query LaunchConfigurations[*].[KeyName] --output text)"
	echo "KEY NAME is: $KEY_NAME"
}

# Get the security group settings of the current launch config to use for the new one
function getSecurityGroups {
	SGs="$(aws autoscaling describe-launch-configurations --launch-configuration-names $LC --region $REG --query LaunchConfigurations[*].[SecurityGroups] --output text)"
	echo "SGs are: $SGs"
}

# Get the image ID the current launch config uses to use for the new one
function getImageID {
	IMAGE_ID="$(aws autoscaling describe-launch-configurations --launch-configuration-names $LC --region $REG --query LaunchConfigurations[*].[ImageId] --output text)"
	echo "IMAGE ID is: $IMAGE_ID"
}

# Get the instance type setting of the current launch config to use for the new one
function getInstanceType {
	INSTANCE_TYPE="$(aws autoscaling describe-launch-configurations --launch-configuration-names $LC --region $REG --query LaunchConfigurations[*].[InstanceType] --output text)"
	echo "INSTANCE TYPE is: $INSTANCE_TYPE"
}

# Function to remove the launch config from the ASG
# This has to be done before the launch config can be deleted
# The best way to 'remove' is to change it to a different launch config temporarily
removeLCfromASG(){
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name $LC --launch-configuration-name dev-next-amee --region $REG
}

# Function to delete the launch config
deleteLC(){
	aws autoscaling delete-launch-configuration --launch-configuration-name $LC --region $REG
}

# Function to create a new launch config from an AMI
createLC(){
	aws autoscaling create-launch-configuration --launch-configuration-name $LC --image-id $IMAGE_ID --key-name $KEY_NAME --security-groups $SGs --instance-type $INSTANCE_TYPE --iam-instance-profile $IAM_ROLE --region $REG
}

# Set the new launch config as the default for the ASG
addLCtoASG(){
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name $LC --launch-configuration-name $LC --region $REG
}

validateInputParameters ${@}
getIAMRole
getKeyName
getSecurityGroups
getImageID
getInstanceType
removeLCfromASG
deleteLC
createLC
addLCtoASG
