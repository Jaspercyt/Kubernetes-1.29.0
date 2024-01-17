#!/bin/bash

# 定義 Google Cloud 的區域
ZONE="us-west4-a"

# 定義節點設置腳本的 URL
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh"

# 定義節點的 IP 位址
NODE_IPS=("192.168.56.11" "192.168.56.12")

# 定義一個函數來設置節點
setup_node() {
  local node=$1  # 節點名稱
  local ip=$2    # 節點 IP

  # 通過 SSH 連接到節點，並下載並執行節點設置腳本
  gcloud compute ssh $node --zone=$ZONE --command="wget -O /home/\$(whoami)/1-setup-node.sh $SETUP_SCRIPT_URL && bash /home/\$(whoami)/1-setup-node.sh"
  # 將 kubeadm-join 腳本複製到節點
  gcloud compute scp kubeadm-join $node:'/home/$(whoami)/' --zone=$ZONE
  # 在節點上設置 kubeadm-join 腳本的執行權限，並執行它
  gcloud compute ssh $node --zone=$ZONE --command="chmod +x /home/\$(whoami)/kubeadm-join && sudo sh /home/\$(whoami)/kubeadm-join"
  # 更新節點的 kubelet 配置，並重啟服務
  gcloud compute ssh $node --zone=$ZONE --command="sudo sed -i 'a KUBELET_EXTRA_ARGS=\"--node-ip=$ip\"' /var/lib/kubelet/kubeadm-flags.env && sudo systemctl daemon-reload && sudo systemctl restart kubelet"
  # 清理節點上的臨時檔案
  gcloud compute ssh $node --zone=$ZONE --command="rm -rf /home/\$(whoami)/1-setup-node.sh /home/\$(whoami)/cni-plugins-linux-amd64-v1.4.0.tgz /home/$(whoami)/containerd-1.7.11-linux-amd64.tar.gz /home/$(whoami)/kubeadm-join /home/$(whoami)/runc.amd64"
}

# 遍歷每個節點 IP 位址，並調用 setup_node 函數來設置對應的節點
for i in ${!NODE_IPS[@]}; do
  setup_node "worker0$((i+1))" "${NODE_IPS[$i]}"
done