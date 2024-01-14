#!/bin/bash

ZONE="us-west4-a"
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/Jaspercyt/Kubernetes-1.29.0/main/GCP-env/GCE-shell/1-setup-node.sh"
NODE_IPS=("192.168.56.11" "192.168.56.12")

setup_node() {
  local node=$1
  local ip=$2

  gcloud compute ssh $node --zone=$ZONE --command="wget -O /home/\$(whoami)/1-setup-node.sh $SETUP_SCRIPT_URL && bash /home/\$(whoami)/1-setup-node.sh"
  gcloud compute scp kubeadm-join $node:/home/$(whoami)/ --zone=$ZONE
  gcloud compute ssh $node --zone=$ZONE --command="chmod +x /home/\$(whoami)/kubeadm-join && sudo sh /home/\$(whoami)/kubeadm-join"
  gcloud compute ssh $node --zone=$ZONE --command="sudo sed -i 'a KUBELET_EXTRA_ARGS=\"--node-ip=$ip\"' /var/lib/kubelet/kubeadm-flags.env && sudo systemctl daemon-reload && sudo systemctl restart kubelet"
  gcloud compute ssh $node --zone=$ZONE --command="rm -rf /home/\$(whoami)/1-setup-node.sh /home/\$(whoami)/cni-plugins-linux-amd64-v1.4.0.tgz /home/\$(whoami)/containerd-1.7.11-linux-amd64.tar.gz /home/\$(whoami)/kubeadm-join /home/\$(whoami)/runc.amd64"
}

for i in ${!NODE_IPS[@]}; do
  setup_node "worker0$((i+1))" "${NODE_IPS[$i]}"
done
