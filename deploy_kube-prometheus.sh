#!/bin/bash
# deploy latest kube-prometheus on kubernetes

# usage:
# $0 - run this script on the machine where you install and configure kubectl
# $0 uninstall - remove kube-prometheus deployment

set -xe

if [ "$1" = uninstall ]; then
    kubectl delete --ignore-not-found=true -f kube-prometheus/manifests/ -f kube-prometheus/manifests/setup
    exit 0
fi

rm -rf kube-prometheus

git clone https://github.com/coreos/kube-prometheus.git

kubectl create -f kube-prometheus/manifests/setup
while ! kubectl get servicemonitors --all-namespaces | grep monitoring; do
    sleep 10
done
sleep 10

kubectl get crds | grep monitoring.coreos.com

kubectl create -f kube-prometheus/manifests/ 

