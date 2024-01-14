#!/bin/bash

wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/cloud-shell.sh
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/master-node.sh
wget https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/worker-node.sh
bash cloud-shell.sh
bash master-node.sh
bash worker-node.sh