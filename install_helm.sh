#!/bin/bash
# install helm on kubernetes
# and configure tiller service account and and grant cluster admin role

# usage:
# $0 - run this script on the machine where you install and configure kubectl
# $0 uninstall - to uninstall helm

set -ex

# specific helm version
VER=3

### uninstall
if [ "$1" = uninstall ]; then
    helm reset
    # wait untill tiller is gone
    while kubectl get -n kube-system pods | grep tiller-deploy; do
        sleep 10
    done
    kubectl delete serviceaccounts -n kube-system tiller
    kubectl delete clusterrolebindings tiller-cluster-rule
    rm -rf ~/.helm
    exit 0
fi

echo "Installing helm $VER"
if [ "$VER" = "2"  ]; then
    curl -L https://git.io/get_helm.sh | bash
    #curl -L https://git.io/get_helm.sh > get_helm.sh
    #chmod +x get_helm.sh
    #./get_helm.sh --version $VER
elif [ "$VER" = "3" ]; then
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# helm init: deploy tiller

#if [ "$VER" = v2.14.3 ]; then
# helm v2.14.3 init doesn't work with k8s 1.16 due to the API version change
# workaround
#    helm init --service-account tiller --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | sed 's@  replicas: 1@  replicas: 1\n  selector: {"matchLabels": {"app": "helm", "name": "tiller"}}@' | kubectl apply -f -
# fi

helm init --service-account tiller
# create service account: tiller
kubectl create serviceaccount --namespace kube-system tiller
kubectl get -n kube-system serviceaccounts tiller

# and grant cluster admin permission to tiller
# as the prometheus, istio helm chart installation requires the permission
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl get clusterrolebinding tiller-cluster-rule

# wait until tiller pod running
while ! kubectl get -n kube-system pods | grep tiller-deploy | grep Running; do
    sleep 10
done
helm version

# add bash completion
if ! grep -q "helm completion bash" ~/.bashrc; then
    cat >>  ~/.bashrc <<EOF
command -v helm &>/dev/null && source <(helm completion bash)
EOF
fi

