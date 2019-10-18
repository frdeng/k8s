#!/bin/bash
# deploy latest kube-prometheus on kubernetes

# usage:
# run this script on the machine where you install and configure kubectl

set -ex

rm -rf kube-prometheus

git clone https://github.com/coreos/kube-prometheus.git

kubectl create -f kube-prometheus/manifests/

sleep 30
kubectl get crds | grep  monitoring

# need to re-try here
kubectl create -f kube-prometheus/manifests/
