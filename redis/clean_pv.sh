#!/bin/bash

#set -ex
set -x

for i in {0..5}; do
    j=$((31 + i*2))
    sudo mount 10.0.10.$j:/pv$i /mnt
    sudo rm -rf /mnt/*
    sudo umount /mnt
    kubectl delete persistentvolumeclaims redis-data-redis-app-$i
    #kubectl delete persistentvolume nfs-pv$i
done

sleep 3
for i in {0..5}; do
    kubectl delete persistentvolume nfs-pv$i
done
