#!/bin/bash

# [任務 1] 安裝 kubeadm
echo "----------------------------------------------------------------------------------------"
echo "[TASK 1] Installing kubeadm"
echo "----------------------------------------------------------------------------------------"
# 安裝 Kubernetes 可以透過 kubeadm、kop 或 kubespray，這次使用 kubeadm 來安裝。
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/

# 進行安裝 kubeadm 的前置作業
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
sudo swapoff -a  # 關閉 swap 空間，因為 Kubernetes 不支援 swap
sudo sed -i '/swap/d' /etc/fstab  # 從 fstab 中移除 swap 相關的內容，避免在重啟後 swap 被打開
sudo timedatectl set-timezone Asia/Taipei  # 設定時區為台北時間

# [任務 2] 安裝 container runtime
echo "----------------------------------------------------------------------------------------"
echo "[TASK 2] Installing a container runtime"
echo "----------------------------------------------------------------------------------------"
# Kubernetes 需要一個 container runtime 環境，這裡我們將安裝 containerd。
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
# 參考資料: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

# 設定必要的系統參數，以便 Kubernetes 正常運行
# 增加 overlay 和 br_netfilter 模組
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 設定必要的 sysctl 參數，這些設置會在重啟後持續生效
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system  # 套用這些 sysctl 設定，無需重啟

# 驗證 br_netfilter 和 overlay 模組是否已經載入
lsmod | grep br_netfilter
lsmod | grep overlay

# 驗證 sysctl 設置是否正確
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# 安裝 containerd 作為 container runtime
# 下載並解壓 containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.11/containerd-1.7.11-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.11-linux-amd64.tar.gz

# 下載並安裝 containerd 服務檔案
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# 安裝 runc
wget https://github.com/opencontainers/runc/releases/download/v1.1.11/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# 安裝 CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz

# 產生並儲存 containerd 的預設配置檔，並修改 containerd 的設定檔，將 SystemdCgroup 的設定從 false 改為 true，讓 containerd 使用 systemd 來管理 cgroup
sudo mkdir -p /etc/containerd/
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# [任務 3] 安裝 kubeadm, kubelet 和 kubectl
echo "----------------------------------------------------------------------------------------"
echo "[TASK 3] Installing kubeadm, kubelet and kubectl"
echo "----------------------------------------------------------------------------------------"
# kubeadm: 用於啟動 Cluster 的命令。
# kubelet: 在 Cluster 中所有機器上運行的組件，負責啟動 pod 和容器。
# kubectl: 用於與 Cluster 通信的命令行工具。
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

# 更新 apt 套件索引並安裝使用 Kubernetes apt 倉庫所需的套件
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# 下載 Kubernetes 套件倉庫的公開簽名金鑰
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 添加 Kubernetes apt 倉庫
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 更新 apt 套件索引，安裝並固定 kubelet, kubeadm 和 kubectl 的版本
sudo apt-get update
sudo apt-get install -y kubeadm=1.29.0-1.1 kubelet=1.29.0-1.1 kubectl=1.29.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl

echo "----------------------------------------------------------------------------------------"
echo "[TASK 4] 安裝其他工具"
echo "----------------------------------------------------------------------------------------"
sudo apt-get update
# 安裝開發相關工具
sudo apt-get install -y git cmake build-essential
# 安裝文字編輯器
sudo apt-get install -y vim yamllint shellcheck
# 安裝網路分析工具
sudo apt-get install -y tcpdump tig socat bridge-utils net-tools
# 安裝系統和文件工具
sudo apt-get install -y tree jq