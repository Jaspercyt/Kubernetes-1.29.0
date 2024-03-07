#!/bin/bash

# 定義環境變數
ZONE="us-west4-a"                               # 指定 Region
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh" # 設定節點的腳本 URL
NODE_IPS=("192.168.56.11" "192.168.56.12")      # worker node 的 IP 陣列

# 定義 setup_node 函式
setup_node() {
  local node=$1  # 參數1: 節點名稱
  local ip=$2    # 參數2: 節點 IP 地址

  # 透過 gcloud compute ssh 命令遠端登入節點：
  # 1. 下載設定節點所需的腳本到用戶家目錄並執行
  gcloud compute ssh $node --zone=$ZONE --command="wget -O /home/\$(whoami)/1-setup-node.sh $SETUP_SCRIPT_URL && bash /home/\$(whoami)/1-setup-node.sh"
  # 2. 把 kubeadm-join 腳本複製到節點上，讓 worker node 加入 Kubernetes 叢集
  gcloud compute scp kubeadm-join $node:'/home/$(whoami)/' --zone=$ZONE
  # 3. 設定 kubeadm-join 腳本執行權限並加入叢集
  gcloud compute ssh $node --zone=$ZONE --command="chmod +x /home/\$(whoami)/kubeadm-join && sudo sh /home/\$(whoami)/kubeadm-join"
  # 4. 修改 kubelet 的啟動參數，設定節點 IP 並重啟 kubelet
  gcloud compute ssh $node --zone=$ZONE --command="sudo sed -i 'a KUBELET_EXTRA_ARGS=\"--node-ip=$ip\"' /var/lib/kubelet/kubeadm-flags.env && sudo systemctl daemon-reload && sudo systemctl restart kubelet"
  # 5. 清理安裝過程中產生的臨時檔案
  gcloud compute ssh $node --zone=$ZONE --command="rm -rf /home/\$(whoami)/1-setup-node.sh /home/\$(whoami)/cni-plugins-linux-amd64-v1.4.0.tgz /home/$(whoami)/containerd-1.7.11-linux-amd64.tar.gz /home/$(whoami)/kubeadm-join /home/$(whoami)/runc.amd64"
}

# 迴圈讀取 NODE_IPS 陣列，對每個 worker node 調用 setup_node 函式進行設定
for i in ${!NODE_IPS[@]}; do
  setup_node "worker0$((i+1))" "${NODE_IPS[$i]}"
done