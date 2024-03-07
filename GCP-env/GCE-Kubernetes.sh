#!/bin/bash

wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/cloud-shell.sh && bash cloud-shell.sh && \
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/master-node.sh && bash master-node.sh && \
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/worker-node.sh && bash worker-node.sh && \
rm -rf GCE-Kubernetes.sh cloud-shell.sh master-node.sh worker-node.sh 1-setup-node.sh 2-master-node.sh kubeadm-join