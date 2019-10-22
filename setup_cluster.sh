#!/bin/bash

# k8s cluster setup script with kubeadm

# setup kubenetes cluster with kubeadm
# 1 master, 2+ worker nodes all running Centos 7
# The script creates latest kubenetes, also deploys Calico pod network add-on.
# tested: k8s v1.15.4, -  v1.16.1

# Usage:

# 1. modify instance public IPs below, and login user name, the login user should be able to sudo without password.
# 2. setup ssh public key authenticatoin from your linux machine to the 3 instances.
# 3. run this script on you linux macine
#   $0 reset - clean up k8s cluster on all nodes
#   $0 create k8s cluster

set -xe
# install specific version k8s
# KVER=1.16.1-0

# log in user
USER=opc

# master and worker nodes pubblic IP
MASTER_PUBLIC_IP=129.146.116.144
NODE0_PUBLIC_IP=129.146.200.71
NODE1_PUBLIC_IP=129.146.201.49

CLUSTER_PUBLIC_IPS="$NODE0_PUBLIC_IP $NODE1_PUBLIC_IP $MASTER_PUBLIC_IP"
NODE_PUBLIC_IPS="$NODE0_PUBLIC_IP $NODE1_PUBLIC_IP"

# master and worker nodes hostname
# MASTER=frdeng-master
# domainname
#DOMAINNAME=sub05190107241.lsavcn.oraclevcn.co

# master and worker nodes private IP
# MASTER_IP=10.0.1.114
#

# pod network addons
CALICO_POD_NETWORK="192.168.0.0/16"
#CALICO_YML="https://docs.projectcalico.org/v3.8/manifests/calico.yaml"
CALICO_YML="https://docs.projectcalico.org/v3.9/manifests/calico.yaml"

FLANNEL_POD_NETWORK="10.244.0.0/16"
#FLANNEL_YML="https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml"
FLANNEL_YML="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

#pod_network=$CALICO_POD_NETWORK
#network_yml=$CALICO_YML

pod_network=$FLANNEL_POD_NETWORK
network_yml=$FLANNEL_YML

# $1=ip
# $2=cmd
ssh_cmd() {
   ssh $USER@$1 "$2"
}

#### reset
if [ "$1" = reset ]; then
    cmd0="sudo kubeadm reset -f; sudo systemctl restart kubelet; rm -fr \$HOME/.kube; sudo rm -rf /var/log/pods; rm -rf ~/.helm"
    # remove the packags in order to install old version
    cmd1="sudo yum -y remove kubelet kubeadm kubectl"
    for ip in $CLUSTER_PUBLIC_IPS; do
        for cmd in "$cmd0" "$cmd1"; do
            ssh_cmd $ip "$cmd"
        done
    done
    exit 0
fi
### reboot the nodes
if [ "$1" = reboot ]; then
    cmd="sudo reboot"
    for ip in $CLUSTER_PUBLIC_IPS; do
        ssh_cmd $ip "$cmd" || :
    done
    exit 0
fi

#########
# configure /etc/hosts if needed.
# Set SELinux in permissive mode (effectively disabling it)
cmd_disable_selinux="sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"

# disable firewalld
cmd_disable_firewalld="sudo systemctl stop firewalld; sudo systemctl disable firewalld"

# remove swap
cmd_swap="sudo sed -i '/swap/d' /etc/fstab; sudo swapoff -a"

# disable ipv6
cmd_ipv6="sudo bash -c 'cat <<EOF > /etc/sysctl.d/ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
';
sudo sysctl --system"

for ip in $CLUSTER_PUBLIC_IPS; do
    for cmd in "$cmd_disable_selinux" "$cmd_disable_firewalld" "$cmd_swap" "$cmd_ipv6"; do
        ssh_cmd $ip "$cmd"
    done
done

# install docker, and k8s
# add docker-ce yum repo
cmd_add_docker_repo="sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"

# add kubernetes repo
cmd_add_k8s_repo="sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
'"
cmd_install_docker="sudo yum install -y docker-ce"

cmd_install_kube="sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes"
if [ -n "$KVER" ]; then
    cmd_install_kube="sudo yum install -y kubelet-$KVER kubeadm-$KVER kubectl-$KVER --disableexcludes=kubernetes"
fi
cmd_enable="sudo systemctl enable --now docker kubelet"

for ip in $CLUSTER_PUBLIC_IPS; do
    for cmd in "$cmd_add_docker_repo" "$cmd_install_docker" "$cmd_add_k8s_repo" "$cmd_install_kube" "$cmd_enable"; do
        ssh_cmd $ip "$cmd"
    done
done

# patch kubelet for kube-prometheus
#cmd="sudo bash -c 'echo KUBELET_EXTRA_ARGS=\"--authentication-token-webhook=true --authorization-mode=Webhook\" > /etc/sysconfig/kubelet'; sudo systemctl restart kubelet"
#for ip in $CLUSTER_PUBLIC_IPS; do
#    for cmd in "$cmd"; do
#        ssh_cmd $ip "$cmd"
#    done
#done

# Flannel specific config for bridge, pass bridge traffic for flannel
cmd_sysctl="sudo bash -c 'cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
';
sudo sysctl --system"

for ip in $CLUSTER_PUBLIC_IPS; do
    for cmd in "$cmd_sysctl"; do
        ssh_cmd $ip "$cmd"
    done
done

sleep 5

# set up master
#cmd="sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$pod_network"
#cmd="sudo kubeadm init --control-plane-endpoint=$MASTER --pod-network-cidr=$pod_network"
cmd="sudo kubeadm init --pod-network-cidr=$pod_network"
out=$(ssh_cmd $MASTER_PUBLIC_IP "$cmd")

# configure kubectl on master
cmd="mkdir -p \$HOME/.kube;
     sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config;
     sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
ssh_cmd $MASTER_PUBLIC_IP "$cmd"

cmd="grep -q 'kubectl completion bash'  ~/.bashrc || cat >> ~/.bashrc <<EOF
command -v kubectl &>/dev/null && source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
alias kga='kubectl get all'
alias kgak='kubectl get all -n kube-system'
alias kgam='kubectl get all -n monitoring'
alias kgai='kubectl get all -n istio-system'
EOF
"
ssh_cmd $MASTER_PUBLIC_IP "$cmd"

# network addon
cmd="kubectl apply -f $network_yml"
ssh_cmd $MASTER_PUBLIC_IP "$cmd"

# nodes to join the cluster
join_str=$(echo "$out" | tail -2)
cmd="sudo $join_str"
for ip in $NODE_PUBLIC_IPS; do
    ssh_cmd $ip "$cmd"
done
