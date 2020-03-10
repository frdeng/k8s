## OLCNE
https://docs.oracle.com/en/operating-systems/olcne/obe-deploy-olcne/index.html

## Prepare

### Yum
Operator
```
sudo yum -y install oracle-olcne-release-el7
```
Master/worker:
```
sudo yum -y install oracle-olcne-release-el7
sudo yum-config-manager --enable ol7_kvm_utils
```
#### Swap on master and worker nodes
```
sudo swapoff -a
sudo sed -i '/swap/s/\(.*\)/# \1/g' /etc/fstab
```
#### SELinux on master and worker nodes
```
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0
```

### Firewall

Operator
```
sudo firewall-cmd --add-port=8091/tcp --permanent
sudo firewall-cmd --reload
```
master:

```
sudo firewall-cmd --add-masquerade --permanent
sudo firewall-cmd --add-port=8090/tcp --permanent
sudo firewall-cmd --add-port=10250/tcp --permanent
sudo firewall-cmd --add-port=10255/tcp --permanent
sudo firewall-cmd --add-port=8472/udp --permanent
sudo firewall-cmd --add-port=6443/tcp --permanent
sudo firewall-cmd --add-port=10251/tcp --permanent
sudo firewall-cmd --add-port=10252/tcp --permanent
sudo firewall-cmd --add-port=2379/tcp --permanent
sudo firewall-cmd --add-port=2380/tcp --permanent
sudo firewall-cmd --reload
```
worker:
```
sudo firewall-cmd --add-masquerade --permanent
sudo firewall-cmd --add-port=8090/tcp --permanent
sudo firewall-cmd --add-port=10250/tcp --permanent
sudo firewall-cmd --add-port=10255/tcp --permanent
sudo firewall-cmd --add-port=8472/udp --permanent
sudo firewall-cmd --reload
```

### Installation
Operator
```
sudo yum -y install olcnectl olcne-api-server olcne-utils
sudo systemctl enable olcne-api-server.service
```

Master/Worker
```
sudo yum -y install olcne-agent olcne-utils
sudo systemctl enable olcne-agent.service
```
### br
```
sudo modprobe br_netfilter
sudo sh -c 'echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf'
```
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

## Boostrap

Operator

Create certs:
```
cd /etc/olcne
sudo ./gen-certs-helper.sh \
--cert-request-organization-unit "Systest" \
--cert-request-organization "Oracle" \
--cert-request-locality "Redwood City" \
--cert-request-state "CA" \
--cert-request-country US \
--cert-request-common-name kube.usernetwork.oraclevcn.com \
--nodes kube-op,kube-master,kube-worker0,kube-worker1
```
Transfer certs:
```
bash -ex /etc/olcne/configs/certificates/olcne-tranfer-certs.sh
```
platform api server:
```
sudo /etc/olcne/bootstrap-olcne.sh \
--secret-manager-type file \
--olcne-node-cert-path /etc/olcne/configs/certificates/production/node.cert \
--olcne-ca-path /etc/olcne/configs/certificates/production/ca.cert \
--olcne-node-key-path /etc/olcne/configs/certificates/production/node.key \
--olcne-component api-server

```

Master, Worker
platform agent
```
sudo /etc/olcne/bootstrap-olcne.sh \
--secret-manager-type file \
--olcne-node-cert-path /etc/olcne/configs/certificates/production/node.cert \
--olcne-ca-path /etc/olcne/configs/certificates/production/ca.cert \
--olcne-node-key-path /etc/olcne/configs/certificates/production/node.key \
--olcne-component agent
```

Operator:
Create environment
```
olcnectl --api-server 127.0.0.1:8091 environment create \
--environment-name myenvironment \
--update-config \
--secret-manager-type file \
--olcne-node-cert-path /etc/olcne/configs/certificates/production/node.cert \
--olcne-ca-path /etc/olcne/configs/certificates/production/ca.cert \
--olcne-node-key-path /etc/olcne/configs/certificates/production/node.key
```
validate:
```
olcnectl --api-server 127.0.0.1:8091 module list \
--environment-name myenvironment
```
add module to environment:
10.0.10.3 is the master node internal IP.
```
olcnectl --api-server 127.0.0.1:8091 module create \
--environment-name myenvironment \
--module kubernetes --name mycluster \
--container-registry container-registry.oracle.com/olcne \
--apiserver-advertise-address 10.0.10.3 \
--master-nodes kube-master:8090 \
--worker-nodes kube-worker:8090,kube-worker1:8090
```
validate
```
olcnectl --api-server 127.0.0.1:8091 module validate \
  --environment-name myenvironment \
  --name mycluster
```
deploy module
```
olcnectl --api-server 127.0.0.1:8091 module install \
--environment-name myenvironment \
--name mycluster
```
Configure `kubectl`
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
```
Configure bash completion for `kubectl`
```
cat >> ~/.bashrc <<EOF
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
alias kga='kubectl get all'
EOF
```
