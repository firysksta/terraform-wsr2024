#!/bin/bash

cd /home/altlinux/bin

export TF_CLI_CONFIG_FILE=/home/altlinux/bin/cloud.conf
terraform init

export TF_CLI_CONFIG_FILE=/home/altlinux/bin/cloudinit.tf
terraform plan
terraform apply -auto-approve

yc lb nlb get my-nlb --format json | jq -r '.listeners[0].address' > /home/altlinux/lb.ip

yc compute instance get web1 --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address' > /home/altlinux/web1.ip

yc compute instance get web2 --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address' > /home/altlinux/web2.ip
