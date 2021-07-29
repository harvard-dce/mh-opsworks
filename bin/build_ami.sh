#!/bin/bash

set -e

if [ -z "$AWS_PROFILE" ]; then
  echo '$AWS_PROFILE not set'
  echo "Your default aws credentials profile will be used"
fi

stack_id=$(./bin/rake stack:id)

get_id_ip_az() {
  instance=$1
  ip_type=$2
  local id_ip_az=$(
    aws opsworks describe-instances \
      --stack-id $stack_id \
      --query "Instances[?Hostname=='${instance}ami-builder1'].[Ec2InstanceId,$ip_type]" \
      --output text
  )
  echo "$id_ip_az"
}

build_ami() {
  prefix=$1
  instance_id=$2
  ssh_connection=$3

  # See https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html
  $ssh_connection sudo /etc/init.d/monit stop &&
    $ssh_connection sudo /etc/init.d/opsworks-agent stop &&
    $ssh_connection sudo rm -rf /etc/aws/opsworks/ /opt/aws/opsworks/ /var/log/aws/opsworks/ /var/lib/aws/opsworks/ /etc/monit.d/opsworks-agent.monitrc /etc/monit/conf.d/opsworks-agent.monitrc /var/lib/cloud/ /etc/chef &&
    $ssh_connection sudo yum erase -y opsworks-agent-ruby chef
  $ssh_connection sudo yum clean all &&
    $ssh_connection sudo rm -rf /var/cache/yum

  if [[ $(id -u) != 0 ]]; then
    # Delete our account on this machine if we're not running this as root
    # We really shouldn't be.
    $ssh_connection sudo /usr/sbin/userdel -f -r $USER
  fi

  date_string=$(date +"%Y-%m-%dT%H-%M-%S")

  # reset
  echo 'Waiting a few seconds before proceeding...'
  sleep 5
  echo
  echo "Instance prepared. Creating the AMI!"
  echo "It will take a while to build the AMIs. Check in the ec2 console for progress info."
  echo
  ami_id=$(
    aws ec2 create-image --instance-id=$instance_id \
      --name "${prefix}ocopsworks_base_$date_string" \
      --description "${prefix} AMI for oc-opsworks that contains most base packages" \
      --reboot --output text
  )
  aws ec2 create-tags \
    --resources $ami_id \
    --tags "Key=mh-opsworks,Value=1" "Key=released,Value=0" "Key=os,Value=amazonlinux.2018.03"
  echo
}

public_id_ip=$(get_id_ip_az '' 'PublicIp')
private_id_ip=$(get_id_ip_az 'private-' 'PrivateIp')
hostkey_check_off="-o StrictHostKeyChecking=no"

while read id ip; do
  public_id=$id
  public_ip=$ip
done <<<"$public_id_ip"

while read id ip; do
  private_id=$id
  private_ip=$ip
done <<<"$private_id_ip"

build_ami 'private-' $private_id "ssh -q -t -A $hostkey_check_off $public_ip ssh -q -t -A $hostkey_check_off $private_ip"
build_ami '' $public_id "ssh -q -t -A $hostkey_check_off $public_ip"

echo "AMI creation is initiated. You will need to update the 'released' tags to '1' to enable them for new mh-opsworks clusters"
echo "NOTE: this process can only be run once per set of ami-builder instances. To repeat you will need to run the following: "
echo "  ./bin/rake stack:instances:delete stack:instances:init"
