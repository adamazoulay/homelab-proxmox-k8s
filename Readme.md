Manually set up for now, we can automate this later.


### Remote access

1. (ON HOST) Install k3s: `curl -sfL https://get.k3s.io | sh -`
2. (ON HOST) [Add to kubeconfig](https://devops.stackexchange.com/questions/16043/error-error-loading-config-file-etc-rancher-k3s-k3s-yaml-open-etc-rancher)
   1. ```shell
      mkdir ~/.kube 2> /dev/null 
      sudo k3s kubectl config view --raw > "$KUBECONFIG"
      chmod 600 "$KUBECONFIG"
3. (ON REMOTE) Add config to remote machine: `scp adam@192.168.0.21:~/.kube/config ~/.kube/proxmox-homelab`.
4. (ON REMOTE) Edit the config to fill in the IP and name: `nano ~/.kube/proxmox-homelab`.
5. (ON REMOTE) Add to .bashrc (or .zshrc): `export KUBECONFIG=~/.kube/config:~/.kube/proxmox-homelab`
6. (ON REMOTE) Change the context and test: `kubectl ctx homelab`, `kubectl get all`

### ArgoCD

Update the repo url and domain url in `values-seed.yaml` and `values.yaml`. Change the gitea values to point at the
correct github urls.

1. `kubectl create namespace argocd`
2. `helm dependency build ./system/argocd`
3. `helm template ./system/argocd --values ./system/argocd/values-seed.yaml --include-crds | kubectl apply -f -`
4. Get the password for argocd (un: admin): `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
5. View [dashboard](http://localhost:8080): `kubectl port-forward service/release-name-argocd-server 8080:80`

### All apps

Replace the domain name with yours: galactica.host -> my.domain.

1. Fill in the s3 credentials in `./system/csi-s3/secret.yaml`, and apply them `kubectl apply -f ./system/csi-s3/secret.yaml`
2. 