#!/bin/sh
# This file creates required secrets for other services.

# ===================================================
# DB SECRETS
echo "Deploying database secrets..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
    name: db-data
type: Opaque
data:
    username: $(echo $DB_USERNAME | base64 -w0)
    password: $(echo $DB_PASSWORD | base64 -w0)
EOF

# ===================================================
# SMTP SECRETS
echo "Deploying SMTP secrets..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
    name: smtp-data
type: Opaque
data:
    username: $(echo $SMTP_USERNAME | base64 -w0)
    password: $(echo $SMTP_PASSWORD | base64 -w0)
EOF

# ===================================================
# DOCKER SECRETS
echo "Deploying Docker secrets..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
    name: pull-docker-creds
data:
    .dockerconfigjson: $DOCKER_CONFIG_JSON
type: kubernetes.io/dockerconfigjson
EOF
