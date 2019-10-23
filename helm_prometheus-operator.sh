#!/bin/bash
# install/uninstall prometheus-operator helm chart on kubernetes

# prereq:
# install and configure kubectl and helm, see install_helm.sh

# usage:
# $0 - install prometheus-operator helm chart in ns monitoring

# $0 uninstall - remove prometheus-operator

set -xe

name=my-prom

# uninstall
if [ "$1" = uninstall ]; then
    helm delete $name
    kubectl delete crd prometheuses.monitoring.coreos.com ||:
    kubectl delete crd prometheusrules.monitoring.coreos.com ||:
    kubectl delete crd servicemonitors.monitoring.coreos.com ||:
    kubectl delete crd podmonitors.monitoring.coreos.com || :
    kubectl delete crd alertmanagers.monitoring.coreos.com ||:

    exit 0
fi

# install the stable prometheus-operator helm chart:
helm install --name $name --namespace monitoring stable/prometheus-operator
