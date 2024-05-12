Manually set up for now, we can automate this later.

Configure: `./scripts/configure`

### Remote access

1. Edit the metal/inventories/prod.yaml with the machine details.
2. Install ansible:
   ```shell
   pipx install ansible --include-deps
   ```
3. Change root pass, enable ssh, and copy ssh keys over:
   ```shell
   sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
   sudo systemctl restart ssh
   sudo passwd
   ```
4. (ON REMOTE) Install prerequisites:
   ```shell
   make -C ./metal
   ```
5. (ON REMOTE) Ex:
   ```shell
   make -C ./external
   ```
6. Create the secrets for storage and ssl:
   ```shell
   kubectl apply -f ./system/csi-smb/secret.yaml
   kubectl apply -f ./system/cert-manager/secret.yaml
   kubectl apply -f ./apps/media-stack/secret.yaml
   ```
7. (ON REMOTE) Ex:
   ```shell
   make -C ./system
   ```
8. (ON REMOTE) Add to .bashrc (or .zshrc):
   ```shell
   export KUBECONFIG=~/.kube/config:~/.kube/homelab
   ```
9. (ON REMOTE) Change the context and test:
   ```shell
   kubectl ctx homelab
   kubectl get all
   ```

### Post-install

1. Get the password for argocd (un: admin):
   ```shell
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```
2. Get the password for gitea (un: gitea_admin):
   ```shell
   kubectl get secret gitea.admin -n global-secrets -o jsonpath="{.data.password}" | base64 -d
   ```

3. Clean:
   ```shell
   chmod +x ./scripts/hacks
   ./scripts/hacks
   ```
   
3. Passwords:
   ```shell
   ./scripts/kanidm-reset-password admin
   ./scripts/kanidm-reset-password idm_admin
   ```

2. Get passwords:
   ```shell
   kubectl get secret paperless.admin -n global-secrets -o jsonpath="{.data.PAPERLESS_ADMIN_PASSWORD}" | base64 -d
   ```

```shell
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch sc local-path -p '{"ReclaimPolicy":"Retain"}'
```

### GPU Op

https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html

```shell
kubectl create ns gpu-operator

kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update
    
noglob helm install gpu-operator -n gpu-operator --create-namespace \
  nvidia/gpu-operator \
    --set toolkit.env[0].name=CONTAINERD_CONFIG \
    --set toolkit.env[0].value=/var/lib/rancher/k3s/agent/etc/containerd/config.toml \
    --set toolkit.env[1].name=CONTAINERD_SOCKET \
    --set toolkit.env[1].value=/run/k3s/containerd/containerd.sock \
    --set toolkit.env[2].name=CONTAINERD_RUNTIME_CLASS \
    --set toolkit.env[2].value=nvidia \
    --set toolkit.env[3].name=CONTAINERD_SET_AS_DEFAULT \
    --set-string toolkit.env[3].value=true
    
    # --set driver.enabled=false
     
helm delete -n nvidia-gpu-operator $(helm list -n nvidia-gpu-operator | grep nvidia-gpu-operator | awk '{print $1}')
helm uninstall gpu-operator-1714404840 -n gpu-operator
kubectl delete crd clusterpolicies.nvidia.com
kubectl delete namespace gpu-operator
```

Test:
```shell
kubectl exec -it service/plex -- bash
nvidia-smi
```

### Debug

Replace the domain name with yours: galactica.host -> my.domain.

```shell
kubectl port-forward service/argocd-server 8081:443 -n argocd
kubectl port-forward service/plex 32400:32400 -n media-stack
kubectl port-forward service/grafana 8081:80 -n grafana
kubectl port-forward service/speedtest 3000:3000 -n speedtest
kubectl port-forward service/kanidm 8080:443 -n kanidm
kubectl port-forward service/sabnzbd 8080:8080 -n media-stack

KUBECONFIG=~/.kube/homelab kubectl sniff ingress-nginx-controller-6fc6f5764c-dmzlc -c controller -p --socket /run/k3s/containerd/containerd.sock 
KUBECONFIG=~/.kube/homelab kubeshark tap plex
KUBECONFIG=~/.kube/homelab kubeshark tap nginx
KUBECONFIG=~/.kube/homelab kubeshark clean
```

```shell
kubectl get secret registry-admin-secret -n zot -o jsonpath="{.data.password}" | base64 -d
kubectl get secret dex.grafana -n global-secrets -o jsonpath="{.data.client_secret}" | base64 -d
```

csi-s3

```shell
helm template ./system/csi-s3 > tmp.yaml
k apply -f tmp.yaml
```

```shell
helm dependency build ./platform/gitea
helm template ./platform/gitea > tmp.yaml -n gitea
k create namespace gitea
k apply -f tmp.yaml -n gitea

kubectl -n gitea get secret | grep gitea-postgresql | awk '{print $1}'
kubectl -n gitea describe secret gitea-postgresql

kubectl patch pv csi-s3 -p '{"spec":{"ReclaimPolicy":"Retain"}}'
kubectl get pv | tail -n+2 | awk '$5 == "Released" {print $1}' | xargs -I{} kubectl delete pv {}

kubectl exec -it gitea-postgresql-0 -- bash

k create ns testdb
helm install my-release oci://registry-1.docker.io/bitnamicharts/postgresql -n testdb \
  --set image.debug=true
k delete ns testdb
```

```shell
helm dependency build ./system/csi-smb
helm template ./system/csi-smb > tmp.yaml -n csi-smb
k create namespace csi-smb
k apply -f tmp.yaml -n csi-smb
k delete -f tmp.yaml -n csi-smb

k apply -f pvc.yaml

```

```shell
helm dependency build ./system/csi-nfs
helm template ./system/csi-nfs > tmp.yaml -n csi-nfs
k create namespace csi-nfs
k apply -f tmp.yaml -n csi-nfs
k delete -f tmp.yaml -n csi-nfs

k apply -f pvc-nfs.yaml
```

```shell
helm dependency build ./apps/plex
helm template ./apps/plex > tmp.yaml -n plex
kubectl port-forward service/plex 32400:32400 -n plex
```

```shell
kubectl port-forward service/hubble-ui 8080:80 -n kube-system 
kubectl port-forward service/hubble-peer 8080:443 -n kube-system 
kubectl port-forward service/metrics-server 8080:443 -n kube-system 
kubectl port-forward service/netmaker-ui 8080:80 -n netmaker
kubectl port-forward pod/qbitorrent-86b7d7cc86-7zq54 8080:8080 -n media-stack
kubectl exec -it pod/qbitorrent-86b7d7cc86-zxhc2 /bin/bash
```

```shell
kubectl cp wireguard-6fd57798db-l9pgv:/config/peer* /mnt/c/Users/Adam/Downloads 
kubectl exec -it wireguard-6fd57798db-l9pgv /bin/bash
```

