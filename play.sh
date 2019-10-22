# hello-node
kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
#kubectl expose deployment hello-node --type=LoadBalancer --port=8080
#kubectl delete svc hello-node
#  105  kubectl logs hello-node-55b49fb9f8-bw5z7
   
# bootcamp

kubectl run kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --port=8080
#kubectl logs kubernetes-bootcamp-5b48cfdcbd-d57nm
#curl http://localhost:8001/api/v1/namespaces/default/pods/kubernetes-bootcamp-5b48cfdcbd-d57nm/proxy/
#kubectl exec -ti kubernetes-bootcamp-5b48cfdcbd-d57nm bash

kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080

kubectl describe deployment/kubernetes-bootcamp
kubectl describe services/kubernetes-bootcamp
node_port=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')

#curl <cluster ip>:$node_port
kubectl scale deployments/kubernetes-bootcamp --replicas=4

#nginxdemos hello
kubectl run nginxdemo --image nginxdemos/hello:plain-text
# scale
kubectl scale deployment nginxdemo --replicas=4
# expose: NodePort
#kubectl expose deployment nginxdemo --port 80 --type=NodePort
# expose: LB
kubectl expose deployment nginxdemo --port 80 --type=LoadBalancer

# rolling update
#kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
#kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10

# HPA example
#https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
# a simple apache container
#kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80
#kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --limits=cpu=500m --expose --port=80

#kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
#kubectl get hpa
#kubectl run -i --tty load-generator --image=busybox /bin/sh
#Hit enter for command prompt
#while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done
# reattach the load-generator pod
#kubectl attach load-generator-7d549cd44-jljlx -c load-generator -i -t


# two containers pod
kubectl apply -f https://k8s.io/examples/pods/two-container-pod.yaml
