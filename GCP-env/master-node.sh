#!/bin/bash

# 宣告變數
ZONE="us-west4-a"  # 指定操作區域
MASTER="master"  # 主節點的名稱
USER_HOME="/home/$(whoami)"  # 獲取當前使用者的家目錄路徑

# 使用 gcloud 指令透過 SSH 連線到主節點，下載並執行第一個設定腳本
gcloud compute ssh $MASTER --zone=$ZONE --command="wget -O $USER_HOME/1-setup-node.sh https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh && bash $USER_HOME/1-setup-node.sh"

# 使用 gcloud 指令透過 SSH 連線到主節點，下載並執行第二個設定腳本
gcloud compute ssh $MASTER --zone=$ZONE --command="wget -O $USER_HOME/2-master-node.sh https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/2-master-node.sh && bash $USER_HOME/2-master-node.sh"

# 從遠端主節點複製 kubeadm-join 文件到本地使用者家目錄
gcloud compute scp $MASTER:$USER_HOME/kubeadm-token/kubeadm-join $USER_HOME --zone $ZONE

# 定義一個清理命令，用於刪除在主節點上下載和生成的文件
CLEANUP_COMMAND="rm -rf $USER_HOME/1-setup-node.sh $USER_HOME/2-master-node.sh $USER_HOME/cni-plugins-linux-amd64-v1.4.0.tgz $USER_HOME/containerd-1.7.11-linux-amd64.tar.gz $USER_HOME/etcd-v3.5.10-linux-amd64 $USER_HOME/etcd-v3.5.10-linux-amd64.tar.gz $USER_HOME/kubeadm-config.yaml $USER_HOME/kubeadm-token $USER_HOME/runc.amd64"

# 使用 gcloud 指令透過 SSH 連線到主節點執行清理命令
gcloud compute ssh $MASTER --zone=$ZONE --command="$CLEANUP_COMMAND"