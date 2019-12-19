#!/bin/bash
RELEASE_NAME=routing
helm template --name $RELEASE_NAME istio-config | kubectl -v=2 apply -f -