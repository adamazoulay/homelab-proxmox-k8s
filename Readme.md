Manually set up for now, we can automate this later.


### Remote access

1. Install k3s: `curl -sfL https://get.k3s.io | sh -`
2. [Add to kubeconfig](https://devops.stackexchange.com/questions/16043/error-error-loading-config-file-etc-rancher-k3s-k3s-yaml-open-etc-rancher)
3. Add config to remote machine: `scp adam@192.168.0.21:~/.kube/config ~/.kube/proxmox-homelab`.
4. Add to .bashrc (or .zshrc): `export KUBECONFIG=~/.kube/config:~/.kube/proxmox-homelab`

### ArgoCD

1. `kubectl create namespace argocd`
2. `helm dependency build ./system/argocd`
3. `helm template ./system/argocd --values ./system/argocd/values-seed.yaml --include-crds | kubectl apply -f -`
4. Get the password for argocd (un: admin): `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
4. View [dashboard](http://localhost:8080): `kubectl port-forward service/release-name-argocd-server 8080:80`