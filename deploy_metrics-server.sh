#!/bin/bash
# deploy latest metrics-server on kubernetes

# usage:
# run this script on the machine where you install and configure kubectl

set -ex

git clone https://github.com/kubernetes-incubator/metrics-server.git

kubectl apply -f metrics-server/deploy/1.8+/

kubectl patch deploy --namespace kube-system metrics-server --type='json' \
  -p='
- op: add
  path: /spec/template/spec/hostNetwork
  value: true
'

kubectl patch deploy --namespace kube-system metrics-server --type='json' \
  -p='
- op: add
  path: /spec/template/spec/containers/0/args
  value: [--kubelet-insecure-tls, --kubelet-preferred-address-types=InternalIP]
'

