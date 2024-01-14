#!/bin/bash

# 建立一個自定義子網路模式的 VPC (虛擬私有雲)
gcloud compute networks create gcp-kubernetes-vpc --subnet-mode=custom

# 在剛剛建立的 VPC 中建立一個子網路
gcloud compute networks subnets create gcp-kubernetes-subnet \
  --network=gcp-kubernetes-vpc \
  --region=us-west4 \
  --range=192.168.56.0/24

# 建立一個防火牆規則允許 ICMP (網路控制訊息協定) 流量進入
gcloud compute firewall-rules create gcp-kubernetes-vpc-allow-icmp \
  --network=gcp-kubernetes-vpc \
  --allow=icmp \
  --direction=INGRESS \
  --priority=65534 \
  --source-ranges=0.0.0.0/0

# 建立一個防火牆規則允許 SSH (安全外殼協定) 流量進入
gcloud compute firewall-rules create gcp-kubernetes-vpc-allow-ssh \
  --network=gcp-kubernetes-vpc \
  --allow=tcp:22 \
  --direction=INGRESS \
  --priority=65534 \
  --source-ranges=0.0.0.0/0

# 建立防火牆規則允許 HTTP (超文字傳輸協定) 流量進入
gcloud compute firewall-rules create allow-http \
  --network=gcp-kubernetes-vpc \
  --allow tcp:80 \
  --target-tags=http-server \
  --direction=INGRESS

# 建立防火牆規則允許 HTTPS (安全超文字傳輸協定) 流量進入
gcloud compute firewall-rules create allow-https \
  --network=gcp-kubernetes-vpc \
  --allow tcp:443 \
  --target-tags=https-server \
  --direction=INGRESS

# 建立防火牆規則允許負載平衡器的健康檢查流量進入
gcloud compute firewall-rules create allow-lb-health-check \
  --network=gcp-kubernetes-vpc \
  --allow tcp:8080 \
  --source-ranges 35.191.0.0/16,130.211.0.0/22 \
  --direction=INGRESS

# 建立一台名為 master 的虛擬機器，並設定相關參數
gcloud compute instances create master \
  --zone=us-west4-a \
  --machine-type=e2-medium \
  --network=gcp-kubernetes-vpc \
  --subnet=gcp-kubernetes-subnet \
  --network-tier=STANDARD \
  --maintenance-policy=MIGRATE \
  --scopes=default \
  --tags=http-server,https-server \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-standard \
  --boot-disk-device-name=master \
  --private-network-ip=192.168.56.10

# 使用 SSH 連線到 master 虛擬機器，下載並執行設定腳本 1-setup-node.sh
gcloud compute ssh master --zone=us-west4-a --command='wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh -O /home/$(whoami)/1-setup-node.sh && bash /home/$(whoami)/1-setup-node.sh'

# 使用 SSH 連線到 master 虛擬機器，下載並執行設定腳本 2-master-node.sh
gcloud compute ssh master --zone=us-west4-a --command='wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/2-master-node.sh -P /home/$(whoami) && bash /home/$(whoami)/2-master-node.sh'

# 從 master 虛擬機器複製 kubeadm-join 檔案到本機
gcloud compute scp master:/home/$(whoami)/kubeadm-token/kubeadm-join /home/$(whoami) --zone us-west4-a