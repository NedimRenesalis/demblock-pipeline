#!/bin/sh
# ===================================================
# CERT MANAGER - needed for NGINX INGRESS, we are using GCE Ingress
# echo "Deploying cert manager..."
# kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager-legacy.crds.yaml
# kubectl create namespace cert-manager || echo "Namespace exists."
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm upgrade cert-manager --install --wait --timeout 15m0s --atomic --namespace cert-manager jetstack/cert-manager --version v0.14.1

# ===================================================
# CLUSTER ISSUER
echo "Deploying Certificates..."
kubectl apply -f ./k8s/certs.yaml

# INGRESS
echo "Deploying Ingress..."
kubectl apply -f ./k8s/ingress.yaml

# OUTDATED VERSIONS
# =================
# kubectl apply -f ./k8s/prod-cm.yaml
# python3 ./k8s/generate_certs.py | kubectl apply -f -