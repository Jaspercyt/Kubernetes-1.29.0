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

# 建立 Kubernetes cluster
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm
echo "----------------------------------------------------------------------------------------"
echo "[TASK 4] Creating a cluster with kubeadm"
echo "----------------------------------------------------------------------------------------"
# 產生 kubeadm 配置檔案
# 配置包括 Cluster 網絡設定、apiserver、controllerManager 和 scheduler 的額外參數
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "192.168.56.10:6443"
networking:
  podSubnet: 192.168.0.0/16
apiServer:
  certSANs:
    - "192.168.56.10"
  extraArgs:
    feature-gates: "SidecarContainers=true"
    advertise-address: "192.168.56.10"
controllerManager:
  extraArgs:
    feature-gates: "SidecarContainers=true"
scheduler:
  extraArgs:
    feature-gates: "SidecarContainers=true"
---
apiVersion: kubelet.config.k8s.io/v1beta1
featureGates:
  SidecarContainers: true
kind: KubeletConfiguration
EOF
# 初始化 control-plane 節點
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node
sudo kubeadm init --config kubeadm-config.yaml
# 設定非 root 使用者可以使用 kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安裝 Calico 網路 CNI
# 參考資料: https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
echo "----------------------------------------------------------------------------------------"
echo "[TASK 5] Install Calico networking and network policy for on-premises deployments"
echo "----------------------------------------------------------------------------------------"
# 安裝 Calico operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
# 安裝所需的自定義資源配置
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# 啟用 shell 自動補全
# 參考資料: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
echo "----------------------------------------------------------------------------------------"
echo "[TASK 6] Enable shell autocompletion"
echo "----------------------------------------------------------------------------------------"
sudo apt-get install bash-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
source ~/.bashrc

# 產生不會過期的 kubeadm 連接 token
# 參考資料: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/
echo "----------------------------------------------------------------------------------------"
echo "[TASK 7] kubeadm token create"
echo "----------------------------------------------------------------------------------------"
sudo mkdir -p /home/$(whoami)/kubeadm-token
KUBEADM_DIR="/home/$(whoami)/kubeadm-token"
TOKEN_FILE="${KUBEADM_DIR}/token"
SHA256_FILE="${KUBEADM_DIR}/sha256"
JOIN_CMD_FILE="${KUBEADM_DIR}/kubeadm-join"
sudo mkdir -p "$KUBEADM_DIR"
# 產生永久有效的 token
kubeadm token create --ttl 0 > "$TOKEN_FILE"
# 產生 CA 證書的 SHA256 雜湊值
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > "$SHA256_FILE"
# 儲存加入 Cluster 的指令到檔案
echo "sudo kubeadm join 192.168.56.10:6443 --token $(cat "$TOKEN_FILE") --discovery-token-ca-cert-hash sha256:$(cat "$SHA256_FILE")" > "$JOIN_CMD_FILE"

# 將 Cluster 層級的配置傳遞給每個 kubelet
# 參考資料: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#workflow-when-using-kubeadm-init
echo "----------------------------------------------------------------------------------------"
echo "[TASK 8] propagate cluster-level configuration to each kubelet"
echo "----------------------------------------------------------------------------------------"
sudo sed -i 'a KUBELET_EXTRA_ARGS="--node-ip=192.168.56.10"' /var/lib/kubelet/kubeadm-flags.env
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 安裝 etcdctl 工具
# 自動檢測 etcd 版本並下載對應的 etcdctl
echo "----------------------------------------------------------------------------------------"
echo "[TASK 9] 安裝 etcdctl"
echo "----------------------------------------------------------------------------------------"
RELEASE=$(sudo cat /etc/kubernetes/manifests/etcd.yaml | grep "image: registry.k8s.io/etcd:" | cut -d ':' -f 3 | cut -d '-' -f 1)
export RELEASE
wget https://github.com/etcd-io/etcd/releases/download/v${RELEASE}/etcd-v${RELEASE}-linux-amd64.tar.gz
tar -zxvf etcd-v${RELEASE}-linux-amd64.tar.gz
cd etcd-v${RELEASE}-linux-amd64
sudo cp etcdctl /usr/local/bin
etcdctl version

# 安裝 Helm 套件管理工具
# 使用官方 Helm 倉庫並安裝到系統中
echo "----------------------------------------------------------------------------------------"
echo "[TASK 10] 安裝 helm"
echo "----------------------------------------------------------------------------------------"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
# 啟用 Helm 自動補全
helm completion bash | sudo tee /etc/bash_completion.d/helm

echo "----------------------------------------------------------------------------------------"
echo "[TASK 11] 安裝其他工具"
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
