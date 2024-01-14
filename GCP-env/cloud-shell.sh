#!/bin/bash

# 定義網絡和虛擬機器的配置變數
NETWORK="gcp-kubernetes-vpc"  # VPC 名稱
SUBNET="gcp-kubernetes-subnet"  # 子網絡名稱
REGION="us-west4"  # 使用的地區
SUBNET_RANGE="192.168.56.0/24"  # 子網絡 IP 範圍
MACHINE_TYPE="e2-medium"  # 虛擬機器類型
IMAGE_FAMILY="ubuntu-2204-lts"  # 虛擬機器使用的映像檔案族
IMAGE_PROJECT="ubuntu-os-cloud"  # 映像檔案所屬的專案
BOOT_DISK_SIZE="10GB"  # 啟動盤大小
BOOT_DISK_TYPE="pd-standard"  # 啟動盤類型

# 建立自定義模式的 VPC 網絡
gcloud compute networks create $NETWORK --subnet-mode=custom
# 在剛建立的 VPC 網絡中創建子網絡
gcloud compute networks subnets create $SUBNET --network=$NETWORK --region=$REGION --range=$SUBNET_RANGE

# 定義一系列的防火牆規則
FIREWALL_RULES=(
  "gcp-kubernetes-vpc-allow-icmp icmp INGRESS 65534 0.0.0.0/0"
  "gcp-kubernetes-vpc-allow-ssh tcp:22 INGRESS 65534 0.0.0.0/0"
  "allow-http tcp:80 INGRESS http-server"
  "allow-https tcp:443 INGRESS https-server"
  "allow-lb-health-check tcp:8080 INGRESS 35.191.0.0/16,130.211.0.0/22"
  "gcp-kubernetes-vpc-allow-internal icmp,tcp,udp INGRESS 1000 192.168.56.0/24 192.168.56.0/24"
)

# 循環遍歷防火牆規則陣列，為每一條規則建立防火牆
for rule in "${FIREWALL_RULES[@]}"; do
  read -r name allow direction priority source_ranges destination_ranges <<<"$rule"
  gcloud compute firewall-rules create $name --network=$NETWORK --allow=$allow --direction=$direction --priority=$priority --source-ranges=${source_ranges:-0.0.0.0/0} ${destination_ranges:+--destination-ranges=$destination_ranges}
done

# 定義虛擬機器的名稱和私有網絡 IP
INSTANCE_NAMES=("master" "worker01" "worker02")
INSTANCE_IPS=("192.168.56.10" "192.168.56.11" "192.168.56.12")

# 為每一台虛擬機器建立實例
for ((i=0; i<${#INSTANCE_NAMES[@]}; i++)); do
  name="${INSTANCE_NAMES[$i]}"
  ip="${INSTANCE_IPS[$i]}"
  gcloud compute instances create $name \
    --zone=${REGION}-a \
    --machine-type=$MACHINE_TYPE \
    --network=$NETWORK \
    --subnet=$SUBNET \
    --network-tier=STANDARD \
    --maintenance-policy=MIGRATE \
    --scopes=default \
    --tags=http-server,https-server \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$BOOT_DISK_SIZE \
    --boot-disk-type=$BOOT_DISK_TYPE \
    --boot-disk-device-name=$name \
    --private-network-ip=$ip
done
