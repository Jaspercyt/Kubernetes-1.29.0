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
FIREWALL_RULES=(
  "gcp-kubernetes-vpc-allow-icmp"
  "gcp-kubernetes-vpc-allow-ssh"
  "allow-http"
  "allow-https"
  "allow-lb-health-check"
  "gcp-kubernetes-vpc-allow-internal"
)

for rule in "${FIREWALL_RULES[@]}"; do
  gcloud compute firewall-rules delete $rule --quiet
done

# 刪除其他資源
KUBEADM_DIR="/home/$(whoami)/kubeadm-token"
rm -rf $KUBEADM_DIR

# 清理完畢
echo "所有GCP資源已成功刪除。"
