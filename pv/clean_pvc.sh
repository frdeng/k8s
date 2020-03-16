#!/bin/bash



for ns in $(kubectl get ns -o jsonpath="{.items[*].metadata.name}"); do
    for pvc in $(kubectl get pvc -n "$ns" -o jsonpath="{.items[*].metadata.name}"); do
        kubectl delete -n "$ns" pvc "$pvc"
    done
done
