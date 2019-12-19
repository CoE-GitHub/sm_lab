#!/bin/bash
set -x
kubectl create ns kiali-operator
bash <(curl -L https://git.io/getLatestKialiOperator) --operator-install-kiali false
kubectl create secret generic kiali -n kiali-operator --from-literal 'username=admin' --from-literal 'passphrase=admin'
kubectl -n kiali-operator apply -f kiali_cr.yaml
