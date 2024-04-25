Manually set up for now, we can automate this later.

### Remote access

1. Edit the metal/inventories/prod.yaml with the machine details.
2. Install ansible:
   ```shell
   pipx install ansible --include-deps
   ```
3. (ON REMOTE) Install prerequisites:
   ```shell
   make -C ./metal
   ```
4. (ON REMOTE) Ex:
   ```shell
   make -C ./external
   ```
5. (ON REMOTE) Add to .bashrc (or .zshrc):
   ```shell
   export KUBECONFIG=~/.kube/config:~/.kube/homelab
   ```
6. (ON REMOTE) Change the context and test:
   ```shell
   kubectl ctx homelab
   kubectl get all
   ```

### ArgoCD

Update the repo url and domain url in `values-seed.yaml` and `values.yaml`. Change the gitea values to point at the
correct github urls.

1. Create the s3 secret for storage, and set the current storage class to non-default:
   ```shell
   kubectl apply -f ./system/csi-s3/secret.yaml
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
   kubectl port-forward service/release-name-argocd-server 8080:443 -n argocd
   ```

### All apps

Replace the domain name with yours: galactica.host -> my.domain.

1. Set up external secrets:
   ```shell
   KUBE_CONFIG_PATH=~/.kube/proxmox-homelab make -C ./external
   ```

```shell
kubectl port-forward service/grafana 8081:80 -n grafana
kubectl port-forward service/speedtest 3000:3000 -n speedtest
```

```shell
kubectl get secret dex.grafana -n global-secrets -o jsonpath="{.data.client_secret}" | base64 -d
```