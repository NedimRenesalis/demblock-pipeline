#!/bin/sh
# ===================================================
echo "Deploying required k8s dependencies..."
# ===================================================
# CERT MANAGER
echo "Deploying cert manager..."
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager-legacy.crds.yaml
kubectl create namespace cert-manager || echo "Namespace exists."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade cert-manager --install --wait --timeout 15m0s --atomic --namespace cert-manager jetstack/cert-manager --version v0.14.1

# ===================================================
# CLUSTER ISSUER
echo "Deploying ClusterIssuer..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: support@demblock.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
      selector: {}
EOF
