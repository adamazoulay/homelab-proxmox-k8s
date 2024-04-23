Manually set up for now, we can automate this later.


### Remote access

1. (ON HOST) Install k3s:
   ```shell
   curl -sfL https://get.k3s.io | sh -
   ```
2. (ON HOST) [Add to kubeconfig](https://devops.stackexchange.com/questions/16043/error-error-loading-config-file-etc-rancher-k3s-k3s-yaml-open-etc-rancher)
   1. ```shell
      mkdir ~/.kube 2> /dev/null 
      sudo k3s kubectl config view --raw > "$KUBECONFIG"
      chmod 600 "$KUBECONFIG"
3. (ON REMOTE) Add config to remote machine:
   ```shell
   scp adam@192.168.0.21:~/.kube/config ~/.kube/proxmox-homelab
   ```
4. (ON REMOTE) Edit the config to fill in the IP and name: 
   ```shell
   sed -i -e 's/127.0.0.1/192.168.0.21/g' ~/.kube/proxmox-homelab
   sed -i -e 's/default/homelab/g' ~/.kube/proxmox-homelab
   ```
5. (ON REMOTE) Add to .bashrc (or .zshrc):
   ```shell
   export KUBECONFIG=~/.kube/config:~/.kube/proxmox-homelab
   ```
6. (ON REMOTE) Change the context and test:
   ```shell
   kubectl ctx homelab
   kubectl get all
   ```

### ArgoCD

Update the repo url and domain url in `values-seed.yaml` and `values.yaml`. Change the gitea values to point at the
correct github urls.

1. 
   ```shell
   kubectl create namespace argocd
   helm dependency build ./system/argocd
   helm template ./system/argocd --values ./system/argocd/values-seed.yaml --include-crds | kubectl apply -f - -n argocd
   ```
2. Get the password for argocd (un: admin):
   ```shell
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```
3. View [dashboard](http://localhost:8080):
   ```shell
   kubectl port-forward service/release-name-argocd-server 8080:80 -n argocd
   ```

### All apps

Replace the domain name with yours: galactica.host -> my.domain.

1. Create the csi-s3 namespace:
   ```shell
   kubectl create namespace csi-s3
   ```
2. Fill in the s3 credentials in `./system/csi-s3/secret.yaml`, and apply them:
   ```shell
   kubectl apply -f ./system/csi-s3/secret.yaml -n csi-s3
   ```
3. 