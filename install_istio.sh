#!/bin/bash
# install istio on kubernetes

# run this script on the machine where you install and configure kubectl

# note this requires helm is installed and configured with cluster admin role
# see install_helm.sh

# see also:
# https://istio.io/docs/setup/install/helm/
# bookinfo example: https://istio.io/docs/examples/bookinfo/

# usage:
#   install: $0 install
#   uninstall: $0 uninstall
#   deploy bookinfo example: $0 bookinfo

# notes:
# istio v1.3.3 helm installation doesn't work withhelm 2.15

set -ex

if [ "$1" = install ]; then
    # install istioctl
    rm -rf istio-*
    curl -L https://git.io/getLatestIstio | sh -
    export ISTIO_VERSION=$(ls -d istio-* | sed 's/istio-//')
    sudo cp -f istio-$ISTIO_VERSION/bin/istioctl /usr/local/bin

    # helm install istio
    helm install istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system \
    --set tracing.enabled=true \ # enable jaeger
    --set grafana.enabled=true # enable grafana

    # wait until all CRDs created
    sleep 10
    kubectl get crds | grep istio.io
    helm install istio-$ISTIO_VERSION/install/kubernetes/helm/istio --name istio --namespace istio-system
    sleep 10
    kubectl -n istio-system get pods
    # set default istio injection to default ns
    kubectl label namespace default istio-injection=enabled
elif [ "$1" = uninstall ]; then
    helm delete --purge istio || :
    helm delete --purge istio-init || :
    helm delete --purge istio-cni || :
    kubectl delete namespace istio-system || :
elif [ "$1" = bookinfo ]; then
    ISTIO_VERSION=$(ls -d istio-* | sed 's/istio-//')
    # suppose default ns has label: istio-injection=enabled
    kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml
    # collect new metrics
    # kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/telemetry/metrics.yaml
fi
