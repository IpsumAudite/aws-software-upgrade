# aws-software-upgrade
These scripts are used to upgrade software behind an ELB and within an ASG in AWS. Though specific to my environment, with a little tweaking you may find them helpful.

The methodology is as follows:
1) Use UpdateELBSW.sh to propogate your software to all machines that sit behind a load balancer
2) Use UpdateAMI.sh to create a new AMI that will be referenced in the launch config for your auto scaling group
3) Use UpdateLCs.sh to update your luanch config to point at the new AMI and then point your auto scaling group at this updated launch config
