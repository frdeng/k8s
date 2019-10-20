#!/bin/bash
# install istio on kubernetes

# run this script on the machine where you install and configure kubectl
# note this requires helm is installed and configured with cluster admin role
# see install_helm.sh
# see also:
# https://istio.io/docs/setup/install/helm/
# usage:
# install: $0 install
# deploy bookinfo sample: $0 bookinfo

set -ex

if [ "$1" = install ]; then
    # install istioctl
    rm -rf istio-*
    curl -L https://git.io/getLatestIstio | sh -
    export ISTIO_VERSION=$(ls -d istio-* | sed 's/istio-//')
    sudo cp -f istio-$ISTIO_VERSION/bin/istioctl /usr/local/bin

    # helm install istio
    helm install istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system

    # wait until all CRDs created
    sleep 30
    kubectl -n istio-system get crds
    helm install istio-$ISTIO_VERSION/install/kubernetes/helm/istio --name istio --namespace istio-system
    sleep 10
    kubectl -n istio-system get pods
    # set default istio injection to default ns
    kubectl label namespace default istio-injection=enabled
elif [ "$1" = uninstall ]; then
    helm delete --purge istio
    helm delete --purge istio-init
    helm delete --purge istio-cni
    kubectl delete namespace istio-system
elif [ "$1" = bookinfo ]; then
    kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml
fi
