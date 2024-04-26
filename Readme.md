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
6. (ON REMOTE) Ex:
   ```shell
   make -C ./system
   ```
7. (ON REMOTE) Add to .bashrc (or .zshrc):
   ```shell
   export KUBECONFIG=~/.kube/config:~/.kube/homelab
   ```
8. (ON REMOTE) Change the context and test:
   ```shell
   kubectl ctx homelab
   kubectl get all
   ```

### ArgoCD

Update the repo url and domain url in `values-seed.yaml` and `values.yaml`. Change the gitea values to point at the
correct github urls.

1. Create the s3 secret for storage, and set the current storage class to non-default:
   ```shell
   kubectl apply -f ./system/csi-smb/secret.yaml
   ```
2. Spin up argocd:
   ```shell
   kubectl create namespace argocd
   kubectl ns argocd
   helm dependency build ./system/argocd
   helm template ./system/argocd --values ./system/argocd/values-seed.yaml --include-crds | kubectl apply -f - -n argocd
   ```
3. Get the password for argocd (un: admin):
   ```shell
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```
4. View [dashboard](http://localhost:8080):
   ```shell
   kubectl port-forward service/argocd-server 8080:443 -n argocd
   ```
4. Clean:
   ```shell
   chmod +x ./scripts/hacks
   ./scripts/hacks
   ```
   

### All apps

Replace the domain name with yours: galactica.host -> my.domain.

1. Set up external secrets:
   ```shell
   KUBE_CONFIG_PATH=~/.kube/homelab make -C ./external
   ```

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

k create ns testdb
helm install my-release oci://registry-1.docker.io/bitnamicharts/mysql -n testdb \
  --set volumePermissions.enabled=true
k delete ns testdb
```

```shell
helm dependency build ./system/csi-smb
helm template ./system/csi-smb > tmp.yaml -n csi-smb
k create namespace csi-smb
k apply -f tmp.yaml -n csi-smb

k apply -f pvc.yaml
```