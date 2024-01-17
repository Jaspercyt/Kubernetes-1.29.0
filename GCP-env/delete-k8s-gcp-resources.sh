#!/bin/bash

# 定義區域
ZONE="us-west4-a"

# 刪除所有VM實例
INSTANCE_NAMES=("master" "worker01" "worker02")

for name in "${INSTANCE_NAMES[@]}"; do
  gcloud compute instances delete $name --zone=$ZONE --quiet
done

# 刪除VPC網路和子網絡
NETWORK="gcp-kubernetes-vpc"
SUBNET="gcp-kubernetes-subnet"

gcloud compute networks subnets delete $SUBNET --region=$REGION --quiet
gcloud compute networks delete $NETWORK --quiet

# 刪除防火牆規則
gcloud compute firewall-rules delete gcp-kubernetes-vpc-allow-icmp
gcloud compute firewall-rules delete gcp-kubernetes-vpc-allow-ssh
gcloud compute firewall-rules delete allow-http
gcloud compute firewall-rules delete allow-https
gcloud compute firewall-rules delete allow-lb-health-check
gcloud compute firewall-rules delete gcp-kubernetes-vpc-allow-internal

# 刪除子網
gcloud compute networks subnets delete gcp-kubernetes-subnet --region=us-west4

# 刪除網路
gcloud compute networks delete gcp-kubernetes-vpc
