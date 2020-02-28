## OCI
Open Container Initiative
container runtime standard

### runc
runc is one of the runtime implementations of OCI container runtime standard

### kata
kata is another OCI runtime

### firecracker

### gVisor

## containerd
Docker separated dockerd from docker, created containerd

docker ->(gRPC) containerd -> OCI runtimes

## Kubernetes

### CRI
Container runtime interface
from v1.15


CRI implementations:
dockershim, cri-containerd, cri-o, fratki

history:

kubelet -> dockershim -> docker -> containerd -> runc

kubelet -> cri-containerd -> containerd -> runc

kubelet -> cri-o -> runc
        ^cri     ^ oci

### CRI-O
Created for Kubernetes CRI
features:
 - use OCI runtime, defaults to runc
 - image service, manage images
 - CNI, setting up container network
 - generating oci specification?



