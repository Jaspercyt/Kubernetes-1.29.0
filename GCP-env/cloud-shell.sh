#!/bin/bash

# 網路及虛擬機器宣告變數
NETWORK="gcp-kubernetes-vpc"  # VPC 名稱
SUBNET="gcp-kubernetes-subnet"  # 子網絡名稱
REGION="us-west4"  # 使用的地區
SUBNET_RANGE="192.168.56.0/24"  # 子網絡 IP 範圍
MACHINE_TYPE="e2-medium"  # 虛擬機器類型
IMAGE_FAMILY="ubuntu-2204-lts"  # 虛擬機器使用的映像檔案族
IMAGE_PROJECT="ubuntu-os-cloud"  # 映像檔案所屬的專案
BOOT_DISK_SIZE="10GB"  # 啟動盤大小
BOOT_DISK_TYPE="pd-standard"  # 啟動盤類型

# 建立自定義模式的 VPC 網路
gcloud compute networks create $NETWORK --subnet-mode=custom
# 在 VPC network 中建立 Subnet
gcloud compute networks subnets create $SUBNET --network=$NETWORK --region=$REGION --range=$SUBNET_RANGE

# 建立防火牆規則
FIREWALL_RULES=(
  "gcp-kubernetes-vpc-allow-icmp icmp INGRESS 65534 0.0.0.0/0"
  "gcp-kubernetes-vpc-allow-ssh tcp:22 INGRESS 65534 0.0.0.0/0"
  "allow-http tcp:80 INGRESS 1000"
  "allow-https tcp:443 INGRESS 1001"
  "allow-lb-health-check tcp:8080 INGRESS 1002"
  "gcp-kubernetes-vpc-allow-internal icmp,tcp,udp INGRESS 1003"
)

# 遍歷 FIREWALL_RULES 陣列中的每一個規則
for rule in "${FIREWALL_RULES[@]}"; do
  # 將讀取到的規則分解為不同的變數
  # name: 規則名稱, allow: 允許的協議和端口, direction: 流向, priority: 優先級
  # source_ranges: 來源 IP 範圍, destination_ranges: 目的地 IP 範圍
  read -r name allow direction priority source_ranges destination_ranges <<<"$rule"
  
  # 使用 gcloud 指令建立防火牆規則
  # --network: 指定網路, --allow: 設定允許的協議和端口
  # --direction: 設定流向, --priority: 設定優先級
  # --source-ranges: 設定來源 IP 範圍, 預設為任何 IP
  # ${destination_ranges:+--destination-ranges=$destination_ranges}: 如果設定了目的地 IP 範圍，則加入此參數
  gcloud compute firewall-rules create $name \
      --network=$NETWORK \
      --allow=$allow \
      --direction=$direction \
      --priority=$priority \
      --source-ranges=${source_ranges:-0.0.0.0/0} \
      ${destination_ranges:+--destination-ranges=$destination_ranges}
done

# 定義虛擬機器的名稱和私有網絡 IP
INSTANCE_NAMES=("master" "worker01" "worker02")
INSTANCE_IPS=("192.168.56.10" "192.168.56.11" "192.168.56.12")

# 透過迴圈來處理 INSTANCE_NAMES 陣列中的每一個元素
for ((i=0; i<${#INSTANCE_NAMES[@]}; i++)); do
  # 從 INSTANCE_NAMES 陣列中獲取實例名稱
  name="${INSTANCE_NAMES[$i]}"
  # 從 INSTANCE_IPS 陣列中獲取對應的 IP 地址
  ip="${INSTANCE_IPS[$i]}"

  # 使用 gcloud 指令建立一個新的 VM instance
  # --zone: 指定建立 instance 的區域和可用區
  # --machine-type: 指定機器型號
  # --network: 指定網路
  # --subnet: 指定子網路
  # --network-tier: 指定網路層級，這裡為標準層級
  # --maintenance-policy=TERMINATE: 維護政策設定為終止，代表在維護時終止虛擬機器
  # --preemptible: preemptible 的意思是，這個虛擬機可以被 GCP 在需要時中斷，通常價格會比較便宜
  # --maintenance-policy: 指定維護策略，這裡設定為 MIGRATE
  # --no-restart-on-failure: 如果虛擬機器在維護時發生故障，則不要重啟虛擬機器
  # --onHostMaintenance=MIGRATE: 如果虛擬機器在維護時發生故障，則將虛擬機器遷移到其他主機
  # --scopes: 設定訪問控制範圍，這裡使用預設值
  # --tags: 為虛擬機增加標籤，用於網路防火牆規則等
  # --image-family 和 --image-project: 指定使用的映像檔
  # --boot-disk-size, --boot-disk-type, --boot-disk-device-name: 設定 boot disk 的大小、類型和裝置名稱
  # --private-network-ip: 指定實例的私有網路 IP 地址
  gcloud compute instances create $name \
    --zone=${REGION}-a \
    --machine-type=$MACHINE_TYPE \
    --network=$NETWORK \
    --subnet=$SUBNET \
    --network-tier=STANDARD \
    --maintenance-policy=TERMINATE \
    --preemptible \
    --no-restart-on-failure \
    --on-host-maintenance=MIGRATE \
    --scopes=default \
    --tags=http-server,https-server \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$BOOT_DISK_SIZE \
    --boot-disk-type=$BOOT_DISK_TYPE \
    --boot-disk-device-name=$name \
    --private-network-ip=$ip

done