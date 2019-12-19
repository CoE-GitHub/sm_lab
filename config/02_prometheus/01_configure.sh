export GCP_PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

read -p "Is the project ID $GCP_PROJECT_ID for Prometheus correct? (Y/N)" -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo TO FIX:
    echo gcloud config set project XXXXXXX
    exit 1
fi

export GCP_REGION="us-central1"
export GCP_KUBE_CLUSTER="standard-cluster-1" 

echo Vars:
echo Project: $GCP_PROJECT_ID
echo Region: $GCP_REGION
echo Cluster: $GCP_KUBE_CLUSTER
read -p "Are the variables correct (Y/N)" -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    exit 1
fi

kubectl create ns istio-system

./create_prom_config_values.sh

helm fetch stable/prometheus --version 9.0.0 --untar
helm template prometheus --name prometheus --namespace istio-system -f values_prometheus.yaml > prometheus.yaml
kubectl -n istio-system apply -f prometheus.yaml


##
#
##
gcloud iam service-accounts create prometheus-server
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$GCP_PROJECT_ID.svc.id.goog[istio-system/prometheus-server]" \
  prometheus-server@$GCP_PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID\
  --role roles/editor \
  --member "serviceAccount:prometheus-server@$GCP_PROJECT_ID.iam.gserviceaccount.com"
  
kubectl annotate serviceaccount \
  --namespace istio-system \
  prometheus-server \
  iam.gke.io/gcp-service-account=prometheus-server@$GCP_PROJECT_ID.iam.gserviceaccount.com