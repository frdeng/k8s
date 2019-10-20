#!/bin/bash
# deploy Metal LB on kubernetes cluster
# to undeploy metallb

set -xe

# check https://metallb.universe.tf/installation/ for latest release version
# change the git tag
manifest=https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml

# to undeploy metallb
# kubectl delete -f $manifest

usage () {
  echo "Usage:"
  echo "$0 <ip_addresses>"
  echo "ip_addresses samples:"
  echo "10.0.0.1-10.0.0.10"
  echo "10.0.0.0/30"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi
ip_addresses=$1

kubectl apply -f $manifest

cat > metallb_l2_config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ip_addresses
EOF

kubectl apply -f metallb_l2_config.yaml
