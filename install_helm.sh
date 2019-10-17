#!/bin/bash
# install helm on kubernetes
# and configure tiller service account and and grant cluster admin role

# usage:
# run this script on the machine where you install and configure kubectl

set -ex

curl -L https://git.io/get_helm.sh | bash

# helm init
# helm v2.14.3 init doesn't work with k8s 1.16 due to the API version change
# workaround
helm init --service-account tiller --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | sed 's@  replicas: 1@  replicas: 1\n  selector: {"matchLabels": {"app": "helm", "name": "tiller"}}@' | kubectl apply -f -

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
