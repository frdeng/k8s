#!/bin/bash

# dummy k8s cluster setup script with kubeadm

# setup kubenetes cluster with kubeadm
# 1 master, 2+ worker nodes

# setup ssh public key authenticatoin to the 3 instances.

# modify instance public IPs below, and login user name, the login user should be able to sudo without password.

# then run this script on you local machine
# $0 reset - clean up k8s cluster on all nodes
# $0 - create k8s cluster

# the instances should be running Centos 7

# tested: k8s v1.15.3, v1.16.0

set -xe

# master and worker nodes hostname
#MASTER=frdeng-master
#NODE0=frdeng-node0
#NODE1=frdeng-node1
# domainname
#DOMAINNAME=sub05190107241.lsavcn.oraclevcn.co

# master and worker nodes pubblic IP
MASTER_PUBLIC_IP=129.146.61.54
NODE0_PUBLIC_IP=129.146.202.147
NODE1_PUBLIC_IP=129.146.201.49

CLUSTER_PUBLIC_IPS="$NODE0_PUBLIC_IP $NODE1_PUBLIC_IP $MASTER_PUBLIC_IP"

# master and worker nodes private IP
#MASTER_IP=10.0.1.109
#NODE0_IP=10.0.1.110
#NODE1_IP=10.0.1.111
#
#CLUSTER_PRIVATE_IPS="$MASTER_IP $NODE0_IP $NODE1_IP"

# log in user
USER=opc

# pod network addons
CALICO_POD_NETWORK="192.168.0.0/16"
CALICO_YML="https://docs.projectcalico.org/v3.8/manifests/calico.yaml"

FLANNEL_POD_NETWORK="10.244.0.0/16"
FLANNEL_YML="https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml"
#
pod_network=$CALICO_POD_NETWORK
network_yml=$CALICO_YML

# $1=ip
# $2=cmd
ssh_cmd() {
   ssh $USER@$1 "$2"
}

#### reset
if [ "$1" = reset ]; then
    cmd="sudo kubeadm reset -f; sudo systemctl restart kubelet; rm -fr \$HOME/.kube"
    for ip in $CLUSTER_PUBLIC_IPS; do
        for cmd in "$cmd"; do
            ssh_cmd $ip "$cmd"
        done
    done
    # remove the packags in order to install old version
    cmd="sudo yum -y remove kubelet kubeadm kubectl"
    for ip in $CLUSTER_PUBLIC_IPS; do
        for cmd in "$cmd"; do
            ssh_cmd $ip "$cmd"
        done
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

for ip in $CLUSTER_PUBLIC_IPS; do
    for cmd in "$cmd_disable_selinux" "$cmd_disable_firewalld" "$cmd_swap"; do
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

#cmd_install_kube="sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes"
# install 1.15.3 for now until metrics-server works with 1.16
cmd_install_kube="sudo yum install -y kubelet-1.15.3-0 kubeadm-1.15.3-0 kubectl-1.15.3-0 --disableexcludes=kubernetes"
cmd_enable="sudo systemctl enable --now docker kubelet"

for ip in $CLUSTER_PUBLIC_IPS; do
    for cmd in "$cmd_add_docker_repo" "$cmd_install_docker" "$cmd_add_k8s_repo" "$cmd_install_kube" "$cmd_enable"; do
        ssh_cmd $ip "$cmd"
    done
done

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

# set up master
#cmd="sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$pod_network"
cmd="sudo kubeadm init --pod-network-cidr=$pod_network"
out=$(ssh_cmd $MASTER_PUBLIC_IP "$cmd")

cmd="mkdir -p \$HOME/.kube;
     sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config;
     sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
ssh_cmd $MASTER_PUBLIC_IP "$cmd"

# network addon
cmd="kubectl apply -f $network_yml"
ssh_cmd $MASTER_PUBLIC_IP "$cmd"

#for ip in $CLUSTER_PUBLIC_IPS; do
#    for cmd in "$cmd_sysctl"; do
#        ssh_cmd $ip "$cmd"
#    done
#done

join_str=$(echo "$out" | tail -2)
# join cluster from nodes
cmd="sudo $join_str"
for ip in $NODE0_PUBLIC_IP $NODE1_PUBLIC_IP; do
    ssh_cmd $ip "$cmd"
done
