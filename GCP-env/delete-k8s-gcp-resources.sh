#!/bin/bash

# 設定 GCP 資源名稱
NETWORK="gcp-kubernetes-vpc"
SUBNET="gcp-kubernetes-subnet"
FIREWALL_RULES=("gcp-kubernetes-vpc-allow-icmp" "gcp-kubernetes-vpc-allow-ssh" "allow-http" "allow-https" "allow-lb-health-check" "gcp-kubernetes-vpc-allow-internal")
INSTANCE_NAMES=("master" "worker01" "worker02")

# 刪除 VM 實例
for instance in "${INSTANCE_NAMES[@]}"; do
  gcloud compute instances delete $instance --quiet
done

# 刪除防火牆規則
for rule in "${FIREWALL_RULES[@]}"; do
  gcloud compute firewall-rules delete $rule --quiet
done

# 刪除子網絡
gcloud compute networks subnets delete $SUBNET --quiet

# 刪除網絡
gcloud compute networks delete $NETWORK --quiet

echo "所有資源已被刪除。"
