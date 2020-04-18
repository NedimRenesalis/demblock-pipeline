#!/bin/sh
# This script deletes Google Cloud registry images.
# 
# Requirement: logged in and configured GCP project
# Arguments:
#       $1 - Image
#       $2 - Keep last (last images to keep)
IMAGE=$1
TO_KEEP=$2

C=1
COUNTALL="$(gcloud container images list-tags ${IMAGE} --limit=999999 --sort-by=TIMESTAMP --format='get(tags)' | grep -v DIGEST | wc -l)"
TO_DELETE=`expr $COUNTALL - $TO_KEEP`

for digest in $(gcloud container images list-tags ${IMAGE} --limit=999999 --sort-by=TIMESTAMP --format='get(digest)'); do
    if [ "$C" -gt "$TO_DELETE" ]
    then
        echo "[SKIP] Image ${IMAGE}@${digest}"
    else
        echo "[DELETE] Image ${IMAGE}"
        gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
    fi 
    C=$(( $C + 1 ))
done

echo "\n[STATS] Total number of cleaned images: $TO_DELETE/$COUNTALL\n"