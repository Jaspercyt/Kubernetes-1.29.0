#!/bin/bash

# 刪除 VM Instance
gcloud compute instances delete master worker01 worker02 --zone=us-west4-a --quiet

# 刪除 Firewallrules
gcloud compute firewall-rules delete allow-https gcp-kubernetes-vpc-allow-icmp gcp-kubernetes-vpc-allow-ssh allow-http gcp-kubernetes-vpc-allow-internal allow-lb-health-check --quiet

# 刪除 Subnet
gcloud compute networks subnets delete gcp-kubernetes-subnet --region us-west4 --quiet

# 刪除 VPC
gcloud compute networks delete gcp-kubernetes-vpc --quiet

# 從 Cloud Shell 中刪除腳本
rm delete-k8s-gcp-resources.sh
