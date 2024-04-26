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

### All apps

Replace the domain name with yours: galactica.host -> my.domain.

```shell
kubectl port-forward service/grafana 8081:80 -n grafana
kubectl port-forward service/speedtest 3000:3000 -n speedtest
kubectl port-forward service/kanidm 8080:443 -n kanidm
```

```shell
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
kubectl port-forward service/hubble-ui 8080:80 -n kube-system 
kubectl port-forward service/hubble-peer 8080:443 -n kube-system 
```