#!/bin/bash
# deploy latest kube-prometheus on kubernetes

# usage:
# run this script on the machine where you install and configure kubectl

set -xe

rm -rf kube-prometheus

git clone https://github.com/coreos/kube-prometheus.git

kubectl create -f kube-prometheus/manifests/setup
while ! kubectl get servicemonitors --all-namespaces | grep monitoring; do
    sleep 10
done
sleep 10

kubectl get crds | grep monitoring.coreos.com

kubectl create -f kube-prometheus/manifests/ 
