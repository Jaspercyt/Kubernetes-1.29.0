Kubernetes 測試環境安裝
===
###### tags:`Kubernetes` `Google Cloud` `Google Compute Engine` `Vagrant` `VirtualBox`

## 摘要
這個 Repository 的目的在於協助大家學習及實際測試 Kubernetes。

由於 Kubernetes 的安裝有一定的門檻，同時也需要一定的基礎環境操作能力，所以提供 2 種 Kubernetes 測試環境的建置腳本：
* [Google Cloud](https://github.com/Jaspercyt/Kubernetes-1.29.0/tree/main#%E7%92%B0%E5%A2%83-1google-cloud)：
透過 Google Cloud 提供的 Cloud Shell，使用 gcloud 指令進行部署雲端環境並建置 Kubernetes cluster。
* [Oracle VM VirtualBox](https://github.com/Jaspercyt/Kubernetes-1.29.0/tree/main?tab=readme-ov-file#%E7%92%B0%E5%A2%83-2oracle-vm-virtualbox)：
透過 Vagrant 在 Oracle VM VirtualBox 中建置 Kubernetes cluster。

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
| 項次 | 名稱 | 角色 | 說明 | 內部 IP |
|:--------:|:--------:|:--------:|:-------- |:--------:|
|   1   |   Master   |   Control Plane   | The control plane manages the worker nodes and the Pods in the cluster.     |   192.168.56.10   |
|   2   |   Worker01   |   Compute Node   | The worker node(s) host the Pods that are the components of the application workload.     |   192.168.56.11   |
|   3   |   Worker02   |   Compute Node   | The worker node(s) host the Pods that are the components of the application workload.     |   192.168.56.12   |

## Kubernetes 建置環境
### 環境-1：Google Cloud
#### 1. 為何選擇在 GCE 上安裝 Kubernetes 而非直接使用 GKE
* 更彈性的依據需求配置環境
在 Google Compute Engine (GCE) 上安裝 Kubernetes，可以比直接使用 Google Kubernetes Engine (GKE) 客製化環境，並且能夠完全控制 Kubernetes 的各項設定，例如：網路、儲存、作業系統等，較能夠滿足學習 Kubernetes 的需求。
  > 如果是正式環境還是比較建議直接使用 Google Kubernetes Engine。

* 更容易深入學習 Kubernetes
透過手動在 GCE 上部署 Kubernetes，可以深入了解 Kubernetes 的運作機制及 trouble shooting，較能夠滿足學習需求。

* 更細緻的成本控制
在 GCE 上部署 Kubernetes，更能滿足我們的客家精神，相對於 GKE 的託管服務，GCE 提供了更多關於資源使用和優化的控制，可以根據需求調整。

* 更容易獲得維運經驗
使用 GCE 手動部署因為需要自行維護 Kubernetes 因此可以獲得其他維運經驗。較容易培養出移轉到其他雲平台或地端環境的能力。

#### 2. Kubernetes 安裝腳本說明

| 項次 |    腳本名稱    | 摘述                                                                 |
|:----:|:--------------:|:-------------------------------------------------------------------- |
|  1   | GCE-Kubernetes | 主腳本，用於執行其他子腳本           |
|  2   |  cloud-shell   | 設定 GCP 網路環境，包括：VPC、Subnet、Firewall rule 及 VM                      |
|  3   |  master-node   | 設定 Kubernetes 主節點，包括 kubeadm 初始化及其他相關配置            |
|  4   |  worker-node   | 設定 Kubernetes 工作節點，並加入到叢集中                             |
|  5   |  1-setup-node  | 安裝必要的 Kubernetes 元件及 Container Runtimes，為加入叢集的前置作業 |
|  6   | 2-master-node  | 在主節點上進行 Kubernetes 的特定配置，包括 Network plugin 及 Cluster level 相關配置       |
|  7   | delete-k8s-gcp-resources | 清理環境，刪除 GCP 資源 |

```CSS =
GCE-Kubernetes.sh
│
├── cloud-shell.sh
│   └── [設定 GCP 的 VPC、Subnet & VM]
│
├── master-node.sh
│   ├───> 1-setup-node.sh
│   │     └── [Kubernetes 節點基本設定]
│   │
│   └───> 2-master-node.sh
│         └── [主節點特定配置]
│
├── worker-node.sh
│   └───> 1-setup-node.sh
│         └── [Kubernetes 節點基本設定]
│
└── delete-k8s-gcp-resources.sh
    └── [刪除 GCP 資源]

```

> [Kubernetes-1.29.0 > /GCP-env](https://github.com/Jaspercyt/Kubernetes-1.29.0/tree/main/GCP-env)

#### 3. Kubernetes cluster 網路架構
Google Cloud Platform 服務使用包括：VPC、Subnet，以及三台虛擬機，分別作為 Kubernetes cluster 的主節點（Master）和兩個工作節點（Worker01 和 Worker02）。
```bash
                                      +---------------------------------+
                                      |     VPC: gcp-kubernetes-vpc     |
                                      +---------------------------------+
                                                       |
                                                       |
                                                       |
                                      +---------------------------------+
                                      |  Subnet: gcp-kubernetes-subnet  |
                                      |     (CIDR: 192.168.56.0/24)     |
                                      +---------------------------------+
                                         /             |             \
                                        /              |              \
                                       /               |               \
                       +-------------------+ +-------------------+ +-------------------+
                       |      Master       | |     Worker01      | |     Worker02      |
                       | IP: 192.168.56.10 | | IP: 192.168.56.11 | | IP: 192.168.56.12 |
                       +-------------------+ +-------------------+ +-------------------+
                               |_______________________|_______________________|
```

#### 4. 使用 Cloud Shell 部署 Kubernetes 叢集
##### Step 01：開啟 Cloud Shell
* 登入 [GCP console](https://console.cloud.google.com/)。
* 在右上角工具列找到 Cloud Shell 的 icon ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/39d3447e-a2d1-468d-8abf-77557d550682)，點擊後會在底部開啟 Cloud Shell session。
* 在底部 Cloud Shell session 的工具列點擊 ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/fccf6836-2e3a-4a70-a4a9-746b1c0255bb) 可以用新分頁的方式打開 Cloud Shell。

![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/708cfaa2-e07c-4e5f-8cd7-f8d104b0a4ff)


##### Step 02：下載並執行部署腳本
在 Cloud Shell 中執行以下指令
```bash
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-Kubernetes.sh && bash GCE-Kubernetes.sh
```
![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/82b88a87-7387-45db-b60f-ef55ed033ddc)

##### Step 03：驗證是否成功建置 Kubernetes Cluster
在 Cloud Shell 中執行以下指令
* 透過 gcloud compute ssh 請求 master 執行 `kubectl get nodes -o wide` 指令，以檢視 Kubernetes 叢集各節點的狀態。
  ```bash
  gcloud compute ssh master --zone=us-west4-a --command="kubectl get nodes -o wide"
  ```

由於節點 `STATUS` 為 Ready，並且沒有異常的錯誤提示，因此 Kubernetes 已成功安裝並且叢集正在正常運行。
* `STATUS`：Ready 代表節點已經準備好並且可以接受運行容器。
* `ROLES`：master 節點被標記為 control-plane，負責叢集管理和調度工作。worker01 和 worker02 節點沒有標記角色為工作節點，用於運行應用程式的容器。
* `VERSION`：所有節點上的版本都是 v1.29.0。
* `INTERNAL-IP`：每個節點都有分配到內部 IP 地址，使節點間可以互相溝通。
* `OS-IMAGE`：節點運行的是 Ubuntu 22.04.3 LTS
* `CONTAINER-RUNTIME`：containerd://1.7.11。
  ```bash
  NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
  master     Ready    control-plane   11m     v1.29.0   192.168.56.10   <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-gcp   containerd://1.7.11
  worker01   Ready    <none>          9m43s   v1.29.0   192.168.56.11   <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-gcp   containerd://1.7.11
  worker02   Ready    <none>          7m57s   v1.29.0   192.168.56.12   <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-gcp   containerd://1.7.11
  ```

##### Step 04：停止 VM Instance
在 Cloud Shell 中執行以下指令
```bash
gcloud compute instances stop master worker01 worker02 --zone=us-west4-a
```
![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/e2ea55b0-2493-4250-929d-1a8f88753747)

##### Step 05：重啟 VM Instance
在 Cloud Shell 中執行以下指令
```bash
gcloud compute instances start master worker01 worker02 --zone=us-west4-a
```
![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/1a3f8cb1-adc5-4ff6-8791-d659c319409d)

##### Step 06：清理環境，刪除 GCP 資源
在 Cloud Shell 中執行以下指令
```bash
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/delete-k8s-gcp-resources.sh && bash delete-k8s-gcp-resources.sh
```

### 環境-2：Oracle VM VirtualBox
##### Step 01：下載 Repository
* 下載 Repository https://github.com/Jaspercyt/Kubernetes-1.29.0

  ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/9072b052-bb13-41bb-b774-2b02f32b6884)

##### Step 02：開啟下載後的資料夾 `Kubernetes-1.29.0/localhost-env`

* 複製路徑

  ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/7de1a5a5-60f8-42a2-915a-3546a4c84656)

* 開啟 Powershell 或 Terminal，執行以下指令
  ```bash
  PS C:\Users\User> cd D:\learning\Kubernetes-env\1.29.0\localhost-env
  PS D:\learning\Kubernetes-env\1.29.0\localhost-env> vagrant up
  ```

  ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/2a8396a1-6b77-44a0-8b49-3678064a184d)


##### Step 03：驗證是否成功建置 Kubernetes Cluster
* 透過指令 `vagrant ssh master` 進入 Control Plane
  ```bash=
  PS D:\learning\Kubernetes-env\1.29.0\localhost-env> vagrant ssh master
  vagrant@127.0.0.1's password:
  Welcome to Ubuntu 22.04.1 LTS (GNU/Linux 5.15.0-56-generic x86_64)
  
   * Documentation:  https://help.ubuntu.com
   * Management:     https://landscape.canonical.com
   * Support:        https://ubuntu.com/advantage
  
    System information as of Thu Jan 18 12:39:43 AM CST 2024
  
    System load:  0.65625            Processes:             236
    Usage of /:   23.6% of 30.34GB   Users logged in:       0
    Memory usage: 22%                IPv4 address for eth0: 10.0.2.15
    Swap usage:   0%                 IPv4 address for eth1: 192.168.56.10
  
  
  This system is built by the Bento project by Chef Software
  More information can be found at https://github.com/chef/bento
  ```
* 透過指令 `kubectl get nodes -o wide` 各節點 `STATUS` 皆為 Ready，因此 Kubernetes 已成功安裝並且叢集正在正常運行。
  ```bash=
  vagrant@master:~$ kubectl get nodes -o wide
  NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
  master     Ready    control-plane   9m33s   v1.29.0   192.168.56.10   <none>        Ubuntu 22.04.1 LTS   5.15.0-56-generic   containerd://1.7.11
  worker01   Ready    <none>          6m48s   v1.29.0   192.168.56.11   <none>        Ubuntu 22.04.1 LTS   5.15.0-56-generic   containerd://1.7.11
  worker02   Ready    <none>          4m26s   v1.29.0   192.168.56.12   <none>        Ubuntu 22.04.1 LTS   5.15.0-56-generic   containerd://1.7.11
  ```
  ![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/e0331549-e005-406b-8bf5-12c2fc171509)

##### Step 04：清理環境，刪除 Virtual Box 資源

透過指令 `vagrant destroy -f` 刪除虛擬機
```bash=
PS D:\learning\Kubernetes-env\1.29.0\localhost-env> vagrant destroy -f
==> worker-02: Forcing shutdown of VM...
==> worker-02: Destroying VM and associated drives...
==> worker-01: Forcing shutdown of VM...
==> worker-01: Destroying VM and associated drives...
==> master: Forcing shutdown of VM...
==> master: Destroying VM and associated drives...
```
![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/dc9b0a2a-fbd0-4634-8106-0849deaac598)
![image](https://github.com/Jaspercyt/Kubernetes-1.29.0/assets/88648972/ce37dd9c-f651-469f-b9a7-0afb8ed9ff14)
