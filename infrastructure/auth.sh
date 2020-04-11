#!/bin/sh

# auth files
echo "Authentication gcloud"
gcloud auth activate-service-account --key-file=$GC_KEY
gcloud config set project $PROJECT