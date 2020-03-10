### PV
pv.yaml

### configMap
redis-conf.yaml
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-conf
data:
  redis.conf: |
    # turn on AOF pv
    appendonly yes
    # enable cluster
    cluster-enabled yes
    cluster-config-file /var/lib/redis/nodes.conf
    cluster-node-timeout 5000
    # AOF persistent file location
    dir /var/lib/redis
    port 6379
```
### headless service

### redis stateful set
```
```

### create redis resouce
```
kubectl create -f *.yaml
```

### create redis cluser
```
ips=$(kubectl get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP} ')
kubectl exec -it redis-app-0 -- redis-cli --cluster create --cluster-replicas 1 $ips
```
## create svc for redis cluster
