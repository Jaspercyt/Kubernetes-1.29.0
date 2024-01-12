#!/bin/bash

# 建立一個名為 gcp-kubernetes-vpc 的自定義子網路
gcloud compute networks create gcp-kubernetes-vpc --subnet-mode=custom

# 在 gcp-kubernetes-vpc 中建立一個子網路，設定其網段範圍
gcloud compute networks subnets create gcp-kubernetes-subnet \
  --network=gcp-kubernetes-vpc \
  --region=us-west4 \
  --range=192.168.56.0/24

# 建立一條防火牆規則允許 ICMP 封包進入 gcp-kubernetes-vpc
gcloud compute firewall-rules create gcp-kubernetes-vpc-allow-icmp \
  --network=gcp-kubernetes-vpc \
  --allow=icmp \
  --direction=INGRESS \
  --priority=65534 \
  --source-ranges=0.0.0.0/0

# 建立一條防火牆規則允許 SSH (22端口) 連線進入 gcp-kubernetes-vpc
gcloud compute firewall-rules create gcp-kubernetes-vpc-allow-ssh \
  --network=gcp-kubernetes-vpc \
  --allow=tcp:22 \
  --direction=INGRESS \
  --priority=65534 \
  --source-ranges=0.0.0.0/0

# 允許 HTTP (80端口) 流量進入有 http-server 標籤的實例
gcloud compute firewall-rules create allow-http \
  --network=gcp-kubernetes-vpc \
  --allow tcp:80 \
  --target-tags=http-server \
  --direction=INGRESS

# 允許 HTTPS (443端口) 流量進入有 https-server 標籤的實例
gcloud compute firewall-rules create allow-https \
  --network=gcp-kubernetes-vpc \
  --allow tcp:443 \
  --target-tags=https-server \
  --direction=INGRESS

# 允許健康檢查流量 (8080端口) 從特定 IP 範圍進入
gcloud compute firewall-rules create allow-lb-health-check \
  --network=gcp-kubernetes-vpc \
  --allow tcp:8080 \
  --source-ranges 35.191.0.0/16,130.211.0.0/22 \
  --direction=INGRESS

# 建立一個名為 master 的 GCP 虛擬機器，用於部署 Kubernetes 主節點
gcloud compute instances create master \
  --zone=us-west4-a \
  --machine-type=e2-medium \
  --network=gcp-kubernetes-vpc \
  --subnet=gcp-kubernetes-subnet \
  --network-tier=STANDARD \
  --maintenance-policy=TERMINATE \
  --preemptible \
  --scopes=default \
  --tags=http-server,https-server \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-standard \
  --boot-disk-device-name=master \
  --private-network-ip=192.168.56.10 \
  --metadata=startup-script='#! /bin/bash
# 下載並執行安裝腳本
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/2-master-node.sh
bash 1-setup-node.sh
bash 2-master-node.sh
rm -rf *'

# 從 master 節點複製 kubeadm-token 到本地機器
gcloud compute scp --recurse --zone=us-west4-a master:/home/$(gcloud compute ssh master --zone=us-west4-a --command="whoami" --quiet)/kubeadm-token .