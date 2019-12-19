kubectl create ns dev
kubectl label namespace dev istio-injection=enabled

kubectl create ns stage
kubectl label namespace stage istio-injection=enabled

kubectl create ns prod
kubectl label namespace prod istio-injection=enabled


##
# Adding test instances
##
kubectl create ns curlnoistio
kubectl label namespace curlnoistio istio-injection=disabled
kubectl -n curlnoistio apply -f curl.yaml

kubectl create ns curlistio
kubectl label namespace curlistio istio-injection=enabled
kubectl -n curlistio apply -f curl.yaml

