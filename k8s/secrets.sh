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
    username: $(echo -n $DB_USERNAME | base64)
    password: $(echo -n $DB_PASSWORD | base64)
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
    username: $(echo -n $SMTP_USERNAME | base64)
    password: $(echo -n $SMTP_PASSWORD | base64)
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
