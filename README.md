# Kubernetes 測試環境安裝

## 摘要
這個 Repository 的目的在於協助大家學習及實際測試 Kubernetes。由於 Kubernetes 的安裝具有一定的門檻，同時也需要一定的基礎設施環境操作能力，所以提供 2 種 Kubernetes 測試環境的建置腳本：
- [Google Cloud](https://github.com/Jaspercyt/Kubernetes-1.29.0/tree/main#%E7%92%B0%E5%A2%83-1google-cloud)：透過 Google Cloud 提供的 Cloud Shell，使用 gcloud 指令進行部署雲端環境並建置 Kubernetes cluster。
- [Oracle VM VirtualBox](https://github.com/Jaspercyt/Kubernetes-1.29.0/tree/main?tab=readme-ov-file#%E7%92%B0%E5%A2%83-2oracle-vm-virtualbox)：透過 Vagrant 在 Oracle VM VirtualBox 中建置 Kubernetes cluster。

讓大家能夠更專注於 Kubernetes 的學習與實務測試，同時根據自己能夠取得的資源，快速部署和測試 Kubernetes cluster。

## 軟體與版本
| 項次 |         軟體         |  版本  |
|:----:|:--------------------:|:------:|
|  1   |      Kubernetes      | 1.29.0 |
|  2   |        Ubuntu        | 22.04  |
|  3   |      Containerd      | 1.7.11 |
|  4   |     CNI Plugins      | 1.4.0  |
|  5   |        Calico        | 3.27.0 |
|  6   |       Vagrant        | 2.3.4  |
|  7   | Oracle VM VirtualBox | 6.1.40 |

## Kubernetes cluster 架構
| 項次 |     名稱      |     角色      |                                     說明                                      | 內部 IP |
|:----:|:-------------:|:-------------:|:-----------------------------------------------------------------------------:|:-------------------:|
|  1   |  Master  | Control Plane |        叢集的控制平面，負責管理、調度和控制 Kubernetes cluster。         |    192.168.56.10    |
|  2   | Worker01 | Compute Node  | 工作節點，執行由 Master 分配的容器和應用，增強集群的處理能力和高可用性。 |    192.168.56.11    |
|  3   | Worker02 | Compute Node  | 工作節點，執行由 Master 分配的容器和應用，增強集群的處理能力和高可用性。 |    192.168.56.12    |

## Kubernetes 建置環境
### 環境-1：Google Cloud
#### 1. 為何選擇在 GCE 上安裝 Kubernetes 而非直接使用 GKE
- 更彈性的依據需求配置環境
- 更容易深入學習 Kubernetes
- 更細緻的成本控制
- 更容易獲得維運經驗

#### 2. Kubernetes 安裝腳本說明
- GCE-Kubernetes.sh
- cloud-shell.sh
- master-node.sh
- worker-node.sh
- 1-setup-node.sh
- 2-master-node.sh
- delete-k8s-gcp-resources.sh

#### 3. Kubernetes cluster 網路架構
Google Cloud Platform 服務使用包括：VPC、Subnet，以及三台虛擬機，分別作為 Kubernetes cluster 的主節點（Master）和兩個工作節點（Worker01 和 Worker02）。

#### 4. 使用 Cloud Shell 部署 Kubernetes 叢集
- Step 01：開啟 Cloud Shell
- Step 02：下載並執行部署腳本
- Step 03：驗證是否成功建置 Kubernetes Cluster
- Step 04：停止 VM Instance
- Step 05：重啟 VM Instance
- Step 06：清理環境，刪除 GCP 資源

### 環境-2：Oracle VM VirtualBox
- Step 01：下載 Repository
- Step 02：開啟下載後的資料夾 `Kubernetes-1.29.0/localhost-env`
- Step 03：驗證是否成功建置 Kubernetes Cluster
- Step 04：清理環境，刪除 Virtual Box 資源
