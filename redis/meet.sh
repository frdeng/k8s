#!/bin/bash
#set -x
ips=$(kubectl get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP} ')


m=0
for i in {0..5}; do
    n=0
    #for ip in 10.244.1.32; do
    for ip in $ips; do
        if [ $m -ne $n ]; then
        kubectl exec -it redis-app-$i -- redis-cli -c cluster meet $ip 6379
        echo $i $ip
        fi
        m=$((m+1))
    done
    n=$((n+1))
done
