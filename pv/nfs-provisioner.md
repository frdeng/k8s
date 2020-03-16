## Reference
From https://github.com/kubernetes-incubator/external-storage/tree/master/nfs

## Installation
Edit deployment.yaml, change the volume and the volumemount, if you use hostPath, make sure the the worker nodes has the path and sufficient space.

Create nfs-provisioner deployment, rbac and storage class

```
kubectl create -f ./nfs-provisioner
```
## Usage

Create the pissistent volume claim:
```
cat >pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-example
  annotations:
    volume.beta.kubernetes.io/storage-class: "my-nfs"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Mi
EOF

kubectl create -f pvc.yaml

```
