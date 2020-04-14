#!/bin/sh
# This script deletes Google Cloud registry images.
# 
# Requirement: logged in and configured GCP project
IMAGE="eu.gcr.io/demblock/demblock"

COUNTALL="$(gcloud container images list-tags ${IMAGE} --limit=999999 --sort-by=TIMESTAMP  | grep -v DIGEST | wc -l)"
C=0

for digest in $(gcloud container images list-tags ${IMAGE} --limit=999999 --sort-by=TIMESTAMP --format='get(tags)'); do

    if [ $COUNTALL-$C ]
    then
        echo ${IMAGE}@${digest}
        # gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
        C=$C+1
    else
        echo "Deleted $( $C - 1 ) images in ${IMAGE}."
    fi 
done