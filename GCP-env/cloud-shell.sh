#!/bin/bash

# 定義環境變數
NETWORK="gcp-kubernetes-vpc"            # VPC 網路名稱
SUBNET="gcp-kubernetes-subnet"          # Subnet 名稱
REGION="us-west4"                       # 指定 Region
SUBNET_RANGE="192.168.56.0/24"          # Subnet IP Range
MACHINE_TYPE="e2-medium"                # 虛擬機型號
IMAGE_FAMILY="ubuntu-2204-lts"          # 使用 Ububtu 映像檔
IMAGE_PROJECT="ubuntu-os-cloud"         # 映像檔所在的專案
BOOT_DISK_SIZE="10GB"                   # 開機磁碟大小
BOOT_DISK_TYPE="pd-standard"            # 開機磁碟類型

# 創建自定義的 VPC 網路
gcloud compute networks create $NETWORK --subnet-mode=custom

# 在 VPC 網路內建立 Subnet，並指定範圍
gcloud compute networks subnets create $SUBNET --network=$NETWORK --region=$REGION --range=$SUBNET_RANGE

# 定義一組防火牆規則，包括允許 ICMP、SSH、HTTP、HTTPS 連線，以及內部網路溝通
FIREWALL_RULES=(
  "gcp-kubernetes-vpc-allow-icmp icmp INGRESS 65534 0.0.0.0/0"
  "gcp-kubernetes-vpc-allow-ssh tcp:22 INGRESS 65534 0.0.0.0/0"
  "allow-http tcp:80 INGRESS 1000"
  "allow-https tcp:443 INGRESS 1001"
  "allow-lb-health-check tcp:8080 INGRESS 1002"
  "gcp-kubernetes-vpc-allow-internal icmp,tcp,udp INGRESS 1003"
)

# 迴圈讀取並建立所有防火牆規則
for rule in "${FIREWALL_RULES[@]}"; do
  read -r name allow direction priority source_ranges destination_ranges <<<"$rule"
  gcloud compute firewall-rules create $name \
      --network=$NETWORK \
      --allow=$allow \
      --direction=$direction \
      --priority=$priority \
      --source-ranges=${source_ranges:-0.0.0.0/0} \
      ${destination_ranges:+--destination-ranges=$destination_ranges}
done

# 定義 Kubernetes Cluster 節點的名稱及 IP 地址
INSTANCE_NAMES=("master" "worker01" "worker02")
INSTANCE_IPS=("192.168.56.10" "192.168.56.11" "192.168.56.12")

# 迴圈讀取並建立所有 Node
for ((i=0; i<${#INSTANCE_NAMES[@]}; i++)); do
  name="${INSTANCE_NAMES[$i]}"
  ip="${INSTANCE_IPS[$i]}"

  gcloud compute instances create $name \
    --zone=${REGION}-a \
    --machine-type=$MACHINE_TYPE \
    --network=$NETWORK \
    --subnet=$SUBNET \
    --network-tier=STANDARD \
    --maintenance-policy=TERMINATE \
    --preemptible \
    --no-restart-on-failure \
    --scopes=default \
    --tags=http-server,https-server \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$BOOT_DISK_SIZE \
    --boot-disk-type=$BOOT_DISK_TYPE \
    --boot-disk-device-name=$name \
    --private-network-ip=$ip

done