#!/bin/bash

profile=$1

if [ -z $profile ]; then
  profile="default"
fi

build_ami() {
  prefix=$1
  ssh_connection="$(./bin/rake stack:instances:ssh_to hostname=${prefix}ami-builder1) -q"

  # Get rid of the null character on the instance_id.
  instance_id=$($ssh_connection wget -q -O - http://instance-data/latest/meta-data/instance-id | sed "s/[^a-z|0-9|-]//g;")

  # See https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html
  $ssh_connection sudo /etc/init.d/monit stop &&
    $ssh_connection sudo /etc/init.d/opsworks-agent stop &&
    $ssh_connection sudo aptitude purge -y opsworks-agent-ruby opsworks-berkshelf opsworks-ruby2.0 &&
    $ssh_connection sudo rm -rf /etc/aws/opsworks/ /opt/aws/opsworks/ /var/log/aws/opsworks/ \
      /var/lib/aws/opsworks/ /etc/monit.d/opsworks-agent.monitrc \
      /etc/monit/conf.d/opsworks-agent.monitrc /var/lib/cloud/ &&
    $ssh_connection sudo apt-get -y autoremove
    $ssh_connection sudo aptitude clean

  if [[ `id -u` != 0 ]]; then
    # Delete our account on this machine if we're not running this as root
    # We really shouldn't be.
    $ssh_connection sudo userdel -f -r $USER
  fi

  date_string=$(date +"%Y-%m-%dT%H-%M-%S")

  # reset
  echo 'Waiting a few seconds before proceeding...'
  sleep 5
  echo
  echo "Instance prepared. Creating the AMI!"
  echo "It will take a while to build the AMIs. Check in the ec2 console for progress info."
  echo
  ami_id=$(aws --profile $profile ec2 create-image --instance-id=$instance_id --name "${prefix}ocopsworks_base_$date_string" --description "${prefix} AMI for oc-opsworks that contains most base packages" --reboot --output text)
  aws --profile $profile ec2 create-tags --resources $ami_id --tags "Key=mh-opsworks,Value=1" "Key=released,Value=0"
  echo
}

build_ami 'private-'
build_ami

echo "AMI creation is initiated. You will need to update the 'released' tags to '1' to enable them for new mh-opsworks clusters"
