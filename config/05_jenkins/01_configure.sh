#!/bin/bash
set -x
PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

read -p "Is the project ID $PROJECT_ID for CI correct? (Y/N)" -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo TO FIX:
    echo gcloud config set project XXXXXXX
    exit 1
fi

kubectl create ns jenkins
kubectl label namespace jenkins istio-injection=enabled
helm install --namespace jenkins --name jenkins stable/jenkins -f values.yaml
kubectl -n jenkins apply -f policy.yaml

##
#
##
gcloud iam service-accounts create jenkins-delivery
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jenkins/jenkins]" \
  jenkins-delivery@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID\
  --role roles/editor \
  --member "serviceAccount:jenkins-delivery@$PROJECT_ID.iam.gserviceaccount.com"
  
kubectl annotate serviceaccount \
  --namespace jenkins \
  jenkins \
  iam.gke.io/gcp-service-account=jenkins-delivery@$PROJECT_ID.iam.gserviceaccount.com

# Demo purposes, allow jenkins cluster control
kubectl create clusterrolebinding jenkins \
    --clusterrole cluster-admin \
    --serviceaccount=jenkins:jenkins

## Test the workload identity
#kubectl run --rm -it \
#  --generator=run-pod/v1 \
#  --image google/cloud-sdk:slim \
#  --serviceaccount jenkins \
#  --namespace jenkins \
#  workload-identity-test
