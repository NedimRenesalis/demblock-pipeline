#!/bin/sh
# ===================================================
echo "Deploying required k8s dependencies..."
# ===================================================
# CERT MANAGER
# echo "Deploying cert manager..."
# kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager-legacy.crds.yaml
# kubectl create namespace cert-manager || echo "Namespace exists."
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm upgrade cert-manager --install --wait --timeout 15m0s --atomic --namespace cert-manager jetstack/cert-manager --version v0.14.1

# ===================================================
# CLUSTER ISSUER
echo "Deploying Certificates..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.gke.io/v1beta2
kind: ManagedCertificate
metadata:
  name: demblock-certs
spec:
  domains:
    - demblock.com
    - backend.demblock.com
---
apiVersion: networking.gke.io/v1beta2
kind: ManagedCertificate
metadata:
  name: demblock-tge-certs
spec:
  domains:
    - demblock-tge.com
    - backend.demblock-tge.com
    - token.demblock-tge.com
EOF