# k8s

## Cluster

Initialize cluster:
```
$ ./setup_cluster.sh
```

Reset cluster:
```
$ ./setup_cluster.sh reset
```

## Deploy metrics-server
```
$ ./deploy_metrics-server.sh
```

## Deploy kube-prometheus
```
$ ./deploy_kube-prometheus.sh
```
Notes:
* If you already have `metrics-server` deployed,  you may see some metrics api conflict error, just ignore.

## Install helm
```$ ./install_helm.sh```

## Deploy metalLB (Optional)
```$ ./deploy_metallb.sh```

## Install Istio
Install and deploy istio using `helm`, so install `helm` first.
```
$ ./install_istio.sh install
```
Notes:
* istio deployment requires a lot cpu resource, on my 2 node, 2vcpu per node cluster, I have to delete previously deployed `kube-prometheus` to free cpu resource in order to deploy `Istio`.
* In order to play virtualservice, istio-ingressgateway neeeds to be working, so need to deploy metallb first.

Deploy the `bookinfo` example:
```
$ ./install_istio.sh bookinfo
