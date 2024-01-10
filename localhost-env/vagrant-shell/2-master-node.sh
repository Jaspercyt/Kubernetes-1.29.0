#!/bin/bash

# 建立 Kubernetes 集群
# 參考文件: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm
echo "----------------------------------------------------------------------------------------"
echo "[TASK 1] Creating a cluster with kubeadm"
echo "----------------------------------------------------------------------------------------"
# 產生 kubeadm 配置檔案
# 配置包括叢集網絡設定、apiserver、controllerManager 和 scheduler 的額外參數
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
# 參考文件: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node
sudo kubeadm init --config kubeadm-config.yaml
# 設定非 root 使用者可以使用 kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安裝 Calico 網路 CNI
# 參考文件: https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
echo "----------------------------------------------------------------------------------------"
echo "[TASK 2] Install Calico networking and network policy for on-premises deployments"
echo "----------------------------------------------------------------------------------------"
# 安裝 Calico operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
# 安裝所需的自定義資源配置
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# 啟用 shell 自動補全
# 參考文件: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
echo "----------------------------------------------------------------------------------------"
echo "[TASK 3] Enable shell autocompletion"
echo "----------------------------------------------------------------------------------------"
sudo apt-get install bash-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
source ~/.bashrc

# 產生不會過期的 kubeadm 連接 token
# 參考文件: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/
echo "----------------------------------------------------------------------------------------"
echo "[TASK 4] kubeadm token create"
echo "----------------------------------------------------------------------------------------"
KUBEADM_DIR="/vagrant/kubeadm"
TOKEN_FILE="${KUBEADM_DIR}/token"
SHA256_FILE="${KUBEADM_DIR}/sha256"
JOIN_CMD_FILE="${KUBEADM_DIR}/kubeadm-join"
mkdir -p "$KUBEADM_DIR"
# 產生永久有效的 token
kubeadm token create --ttl 0 > "$TOKEN_FILE"
# 產生 CA 證書的 SHA256 雜湊值
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > "$SHA256_FILE"
# 儲存加入叢集的命令到檔案
echo "sudo kubeadm join 192.168.56.10:6443 --token $(cat "$TOKEN_FILE") --discovery-token-ca-cert-hash sha256:$(cat "$SHA256_FILE")" > "$JOIN_CMD_FILE"

# 將 Cluster 層級的配置傳遞給每個 kubelet
# 參考文件: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#workflow-when-using-kubeadm-init
echo "----------------------------------------------------------------------------------------"
echo "[TASK 5] propagate cluster-level configuration to each kubelet"
echo "----------------------------------------------------------------------------------------"
sudo sed -i 'a KUBELET_EXTRA_ARGS="--node-ip=192.168.56.10"' /var/lib/kubelet/kubeadm-flags.env
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 安裝 etcdctl 工具
# 自動檢測 etcd 版本並下載對應的 etcdctl
echo "----------------------------------------------------------------------------------------"
echo "[TASK 6] 安裝 etcdctl"
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
echo "[TASK 7] 安裝 helm"
echo "----------------------------------------------------------------------------------------"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
# 啟用 Helm 自動補全
helm completion bash | sudo tee /etc/bash_completion.d/helm

# [TASK 8] 刪除安裝檔
echo "----------------------------------------------------------------------------------------"
echo "[TASK 8] Delete installation files"
echo "----------------------------------------------------------------------------------------"
rm -rf *