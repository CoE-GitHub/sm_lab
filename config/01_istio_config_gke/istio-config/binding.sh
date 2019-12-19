kubectl create clusterrolebinding cluster-admin-binding-1 \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)