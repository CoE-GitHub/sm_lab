# Installation
## Introduction
This lab project is intended to showcase the example integration
of Istio to the microservices.

The worflow of this lab covers preparing the environment from
scratch on Google Cloud Platform and create an end-to-end
solution for application delivery with integrated service mesh
and observability features.

## Components
- Kubernetes as container orchestrator
- Prometheus for monitoring
- OpenTracing for distribited tracing
- Log Correlation, Stackdriver incident analysis
- Istio as Service Mesh
- Helm workloads templating guide for Istio integration

## Repositories involved in the lab
- sm_lab 
```
https://github.com/CoE-GitHub/sm_lab.git
```
- frontend, backend - Example services code
```
https://github.com/CoE-GitHub/backend.git
https://github.com/CoE-GitHub/frontend.git
```
- libchart - reference library Chart implementation for Java services in Istio/Kubernetes environment
```
https://github.com/CoE-GitHub/libchart.git
```

## Scenario
#### Prerequisites
- Install Google Chrome
- Open Incognito windows
- Install Visual Studio Code
- Install Kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/
- Install Skaffold https://skaffold.dev/docs/install/
- Install Helm2 from https://github.com/helm/helm/releases
- Install Gcloud https://cloud.google.com/sdk/docs/quickstarts
- Registered account on Auth0

#### Auth0 account pre-configuration
- Go to Auth0 and signup for the account
- Create a tenant domain in US region
- Copy the tenant domain url (in format xxxxxx.auth0.com)
- Choose personal account
- Open Applications -> Default App
- Copy the Domain field
- Export the domain to environment variable

#### Step A1: Provision Quicklabs environment for experiments
- Provision the LAB environment in Quicklabs using lab GSP654
- Open Incognito windows
- Go co console and enter generated email and password
- In project list choose the dynamic project that was created earlier (project ID provided by quiclabs)

#### Step A2:
- Open Cloud Shell
- Clone this repository to cloud shell (command to paste below)
- Clone frontend repository to cloud shell (command to paste below)
- Clone backend repository to cloud shell (command to paste below)
- Clone libchart (command to paste below)
- Or use all-in one
```
git clone https://github.com/CoE-GitHub/sm_lab.git
git clone https://github.com/CoE-GitHub/frontend.git
git clone https://github.com/CoE-GitHub/backend.git
git clone https://github.com/CoE-GitHub/libchart.git
```

#### Step B1: GKE

##### Basic Settings
- In the left GCP pane navigate to Kubernetes Engine -> Clusters
- Press "Create cluster button"
- Leave standard-cluster-1 as cluster name
- Choose us-central1-a in "Zone" field
- Select master version 1.14 in "Master version" field
- Choose Zonal cluster cluster in "Location type"
- Select 4 nodes in "default-pool" -> "Number of nodes" field
- Select n1-standard-2 as node size in "Machine type" field under default pool
- Check the basic settings
![GKE](doc/gke_basic.png)

##### Advanced settings
- Click on link to expand advanced settings named " Availability, networking, security, and additional features"

- Enable Workload Identity (beta)
- Enable Istio (beta)
- Enable mTLS - Strict (beta)
- Verify that default (Enable Stackdriver Kubernetes Engine Monitoring) is enabled
- Check the advanced settings
![GKE](doc/gke_advanced.png)
- Create the cluster

##### Get cluster credentials
- In the left GCP pane navigate to Kubernetes Engine -> Clusters
- Get the default credentials to the cluster clicking 
"Connect" button and copying the connect string. 
- Example of connect string is below:
```
gcloud container clusters get-credentials epo --zone us-central1-a --project qwiklabs-gcp-XXXXXXXXXXX
```
- Verify the cluster is running with command getting pods from all namespaces
```
kubectl get pods --all-namespaces
```

#### Step C1: Istio configuration
- In terminal open cd ~/sm_lab/config/01_istio_config_gke/
```
cd ~/sm_lab/config/01_istio_config_gke/
```
- Launch init helm script - should complete successfully
```
./00_init_helm.sh
```
- You should get the similar output in the bottom of the executed command
```
NAME                    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)     AGE
service/tiller-deploy   ClusterIP   10.12.4.254   <none>        44134/TCP   3s
```
- Execute Istio configuration script
```
./01_configure.sh
```
- Launch configuration script - apply should complete
- At this point we performed custom istio configuration

#### Step D1: Prometheus
- In terminal open cd ~/sm_lab/config/02_prometheus
```
cd ~/sm_lab/config/02_prometheus
```
- Execute Prometheus configuration script and enter Y for confirm when a prompt appears
```
./01_configure.sh
```
- Verify the output
```
Error from server (AlreadyExists): namespaces "istio-system" already exists
configmap/prometheus-server created
serviceaccount/prometheus-server created
clusterrole.rbac.authorization.k8s.io/prometheus-server created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-server created
service/prometheus-server-headless created
service/prometheus-server created
statefulset.apps/prometheus-server created
```

#### Step D2: Monitoring integration
##### IMPORTANT: Do NOT use BETA monitoring
- In the left GCP pane navigate to Stackdriver -> Monitoring
- Open Stackdriver Monitoring
- Important: Choose "Try Beta" option for Stackdriver monitoring
- Create workspace
- Open Metrics Explorer
- Search for "external" metrics
- Prometheus metrics will be present
![GKE](doc/prometheus_sd.png)

#### Step E1: Kiali
- In terminal open sm_lab/config/03_kiali
- Launch configure script

#### Step F1: Create and configure namespaces
- In terminal open sm_lab/config/04_istio_workload_namespaces
- Launch configure script

#### Step G1: Create and configure Jenkins
- In terminal open sm_lab/config/05_jenkins
- Launch configure script

# Lab
## Introduction
This scenarios contain code examples on 
detailed Istio Features provided by the lab
environment

## Continuos delivery for Kubernetes/Istio on Jenkins
- In the left GCP pane navigate to Kubernetes Engine -> Services and Ingress
- Click on the url of Jenkins service in format IP:8080
```
Note: It takes time for Jenkins to spawn
```
- Login to Jenkins with login=admin, password=adminka

### Create a multibranch pipeline for the service frontend
- In Jenkins UI enter Item Name frontend
- Select Multibranch pipeline 
- Press OK and you will be redirected to job configuration
- Under Branch Sources, click Add Source and choose "Git"
- Under "Project repository" add https://github.com/CoE-GitHub/frontend.git
```
https://github.com/CoE-GitHub/frontend.git
```
![GKE](doc/frontend_mb.png)
- Click Save button
- Navigate to Jenkins -> Frontend (multibranch pipeline) -> master branck job
- Check that a job is running
- Wait for the job to fail (This is on purpose to generate input parameters)
- Launch the job manually entering the GCP project ID in the bottom

### Create a multibranch pipeline for the service frontend
- Create a multibranch pipeline for the service backend for repostory 
```
https://github.com/CoE-GitHub/backend.git
```
- Navigate to Jenkins -> Frontend (multibranch pipeline) -> master branck job
- Check that a job is running
- Wait for the job to fail (This is on purpose to generate input parameters)
- Launch the job manually entering the GCP project ID in the bottom

### Wait for pipelines to complete successfully

## Features
### Traffic management
#### Weighted testing
- Add host of the ingress gateway to your /etc/hosts
For example
```
X.X.X.X  frontend.epo.ss-ops.com
X.X.X.X  backend.epo.ss-ops.com
```

- You can create the entry automatically running the command
```
INGRESIIP=$(kubectl get svc istio-ingressgateway -n istio-system -o json | jq ".status.loadBalancer.ingress[0].ip" | sed -e 's/^"//' -e 's/"$//')
echo $INGRESIIP frontend.epo.ss-ops.com | sudo tee -a /etc/hosts
echo $INGRESIIP backend.epo.ss-ops.com  | sudo tee -a /etc/hosts
echo $INGRESIIP webserver.epo.ss-ops.com  | sudo tee -a /etc/hosts
```

- Try to curl - should be successful if pipeline in Jenkins is complete
```
curl -k https://frontend.epo.ss-ops.com
```
- Edit the virtualservice, follow the end of the document and adjust weight
```
kubectl -n prod edit virtualservice frontend
```

Example weight adjustment:
```
  - route:
    - destination:
        host: frontend-master.prod.svc.cluster.local
        port:
          number: 8080
      weight: 100
    - destination:
        host: frontend-master-canary.prod.svc.cluster.local
        port:
          number: 8080
      weight: 0
```

- Observe how the weight is changed as you do curl requests

#### Header based routing
- Edit the virtualservice and put 100 weight on master and 0 on canary in the end of the document
```
kubectl -n prod edit virtualservice frontend
```
- All the traffic is now directed to master release
- Use the following command to access the canary release
```
curl -k https://frontend.epo.ss-ops.com -H "version: master-canary"
```
- Traffic is sent to pods of canary version

#### Resilience - Timeout
- Test that a service is timing out in a percentage of requests
```
curl -k https://backend.epo.ss-ops.com/delay
```
- Set the service timeout
```
kubectl -n prod edit virtualservice backend
```
Go to the bottom and edit weight and timeout
```
  - route:
    - destination:
        host: backend-master.prod.svc.cluster.local
        port:
          number: 8080
      timeout: 0.2s
      weight: 100
    - destination:
        host: backend-master-canary.prod.svc.cluster.local
        port:
          number: 8080
      weight: 0
    timeout: 0.1s
```
- Retry multiple times the curl
```
curl -k https://backend.epo.ss-ops.com/delay
```
- You should receive upstream request timeout

#### Resilience - Retries
- Edit the virtualservice to enable retries
```
kubectl -n prod edit virtualservice backend
```
- Add retries block to the bottom like in example below:
```
  - route:
    - destination:
        host: backend-master.prod.svc.cluster.local
        port:
          number: 8080
      timeout: 0.2s
      weight: 100
    - destination:
        host: backend-master-canary.prod.svc.cluster.local
        port:
          number: 8080
      weight: 0
    timeout: 0.1s
    retries:
      attempts: 5
```
- Retry multiple times the curl
```
curl -k https://backend.epo.ss-ops.com/delay
```
- Service availability should be increased as if delay happens the request is retried
- Retry multiple times the curl
```
curl -k https://backend.epo.ss-ops.com/fail
```

### Advanced filtering
- Let's immagine a situation where for example a custom logic
is required for application routing, or additional services need to be called.
To do that custom EnvoyFilters can be created.

```
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: frontend-country-router
  namespace: prod
spec:
  filters:
  - listenerMatch:
      listenerType: GATEWAY
    filterName: envoy.lua
    filterType: HTTP
    filterConfig:
      inlineCode: |
        function process(request_handle)
          local function has_value (tab, val)
              for index, value in ipairs(tab) do
                  if value == val then
                      return true
                  end
              end
              return false
          end

          authority = request_handle:headers():get(":authority")
          request_handle:logErr(authority)

          if authority == "frontend.epo.ss-ops.com" then
            request_handle:logErr("Entered authority")
            country = request_handle:headers():get("country")
            request_handle:logErr("Country", country)
            local masterCountries = {'nl', 'it', 'de'}
            local canaryCountries = {'uk', 'us'}
            if has_value(masterCountries, country) then
                request_handle:logErr("Found Master")
                request_handle:headers():add("version", "master")
            else
              if has_value(canaryCountries, country) then
                  request_handle:logErr("Found Canary")
                  request_handle:headers():add("version", "master-canary")
              else
                request_handle:headers():add("version", "master")
              end
            end
            request_handle:logErr("Completed request")
          end
        end

        function envoy_on_request(request_handle)
          process(request_handle)
        end

        function envoy_on_response(response_handle)
          response_handle:headers():add("Processed", "ByEnvoy")
        end
EOF
```
- Test how the additional routing header is injected
```
curl -k https://frontend.epo.ss-ops.com -H 'country: nl'
```
- Change the country to verify traffic is directed to other instance
```
curl -k https://frontend.epo.ss-ops.com -H 'country: us'
```

### Security Features
#### Strict/Permissive MTLS
This demo covers the MTLS settings in Istio.
Initially the cluster was created with MTLS Strict cluster policy.
This means that all connections requires to establish Mutual TLS.
Hovewer Istio permits overriding this settings.

- Browse kubernetes workloads in GKE
- Try to access stage frontend via LoadBalancer - blocked as MTLS required
- Try to access prod frontend via LoadBalancer - blocked as MTLS required
- Apply the following policy:
```
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "frontend"
  namespace: stage
spec:
  targets:
  - name: frontend-master
  peers:
  - mtls:
      mode: PERMISSIVE
```
- Try to access stage frontend via LoadBalancer

#### Service to Service Auth + Authorization
- Create RBAC definition:
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["prod"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-viewer
  namespace: prod
spec:
  rules:
  - services: ["backend*"]
    methods: ["GET"]
  - services: ["frontend*"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-service-viewer
  namespace: prod
spec:
  subjects:
  - properties:
      source.principal: "cluster.local/ns/prod/sa/default"
  roleRef:
    kind: ServiceRole
    name: "service-viewer"
EOF
```
- Go inside the frontend application and check it can access backend prod to prod
```
kubectl -n prod exec -it deployment/frontend-master sh
```
Try
```
curl backend-master:8080
```
Try
```
curl backend-master:8080 -XPOST
```
- Check stage cannot access prod backend
```
kubectl -n stage exec -it deployment/frontend-master sh
```
- Allow access to ingress to frontend application
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-viewer-frontend
  namespace: prod
spec:
  rules:
  - services: ["frontend*"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-service-viewer-ingress
  namespace: prod
spec:
  subjects:
  - properties:
        source.namespace: "istio-system"
  roleRef:
    kind: ServiceRole
    name: "service-viewer-frontend"
EOF
```
- Try accessing backend
```
curl -k https://backend.epo.ss-ops.com
```
- Access frontend
```
curl -k https://frontend.epo.ss-ops.com
```

- Disable RBAC
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["other"]
EOF
```
- Delete rules
```
kubectl -n prod delete servicerolebinding bind-service-viewer-ingress
kubectl -n prod delete servicerolebinding bind-service-viewer
```

#### End user authentication
- Verify that currently service is working
```
curl -k https://frontend.epo.ss-ops.com
```
- Go to Auth0 and signup for the account
- Create a tenant domain in US region
- Copy the tenant domain url (in format xxxxxx.auth0.com)
- Choose personal account
- Open Applications -> Default App
![GKE](doc/auth0_app.png)
- Copy the Domain field
- Export the domain to environment variable
```
export AUTH0_DOMAIN=dev-t18ouxmp.auth0.com
```
- Disable RBAC, in will be enabled later in the flow, but at the moment
it is required to enable Authentication only, to ensure only 
authenticated users are able to access the service.
Authentication != Authorization.
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["disabled"]
---
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
```
- Note at this point policy rules sync takes time. You might see upstream connect errors.
- Configure the manifest
```
cat <<EOF | kubectl apply -f -
---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: default
  namespace: prod
spec:
  origins:
  - jwt:
      issuer: "https://${AUTH0_DOMAIN}/"
      jwksUri: "https://${AUTH0_DOMAIN}/.well-known/jwks.json"
  peers:
  - mtls: {}
  principalBinding: USE_ORIGIN
EOF
```
- Try to curl the service, you will see origin authentication required error
```
curl -k https://frontend.epo.ss-ops.com
```
- Let's configure the authentication, visit  Auth0 Portal > APIs > Create API,
- Enter application URL
- Go to Test tab and open Curl
```
curl -k --request POST \
  --url https://${AUTH0_DOMAIN}.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{"client_id":"${CLIENT_ID}","client_secret":"${CLIENT_ID}","audience":"https://frontend.epo.ss-ops.com","grant_type":"client_credentials"}'
```
- The outout will be a Bearer token. Copy it.
- Call the frontend application with the test code

Example:
```
curl --request GET \
  --url http://path_to_your_api/ \
  --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik5VRTRNVVV3TmXXXXXXXXX......'
```
Copy this unfinished commant line and paste to terminal,
then copy the Bearer token headers setting from Auth0 test panel to match 
the format above and execute the command.

```
curl -k --request GET \
  --url https://frontend.epo.ss-ops.com/ \
```
- At this point you should be able to access the application with the token,
but you should not be able to access the application without the token.
- The line to copy the token from 
![GKE](doc/auth0_token.png)

#### End user authorization - JWT + RBAC using Auth0
- Complete End user authentication section
- Enable RBAC
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["prod"]
EOF
```
- At this point without the token you will see origin authentication failure,
and with the token you will see the RBAC Access denied error

- Create a service role
```
cat <<EOF | kubectl apply -f -
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: end-user-role
  namespace: prod
spec:
  rules:
  - services: ["frontend*"]
    paths: ["*"]
    methods: ["*"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: end-user-role-binding
  namespace: prod
spec:
  subjects:
  - properties:
      request.auth.claims[aud]: "https://frontend.epo.ss-ops.com"
  roleRef:
    kind: ServiceRole
    name: "end-user-role" 
EOF
```
- Explore the jwt token in jwt.io
- Call the frontend application with the test code

Example:
```
curl --request GET \
  --url https://frontend.epo.ss-ops.com/ \
  --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik5VRTRNVVV3TmXXXXXXXXX......'
```
Copy this unfinished commant line and paste to terminal,
then copy the Bearer token headers setting from Auth0 test panel to match 
the format above and execute the command.

```
curl -k --request GET \
  --url https://frontend.epo.ss-ops.com/ \
```


# Troubleshooting task
- Apply definition troubleshooting/trouble_001.yaml
```
kubectl apply -f troubleshooting/trouble_001.yaml
```

- Try to curl the service 
```
curl -k https://webserver.epo.ss-ops.com -v
```
- Fix the Issue and make webserver available externally
- Make sure without editing the VirtualService the responses are always from version 1
- Edit the virtualservice to 50/50 and make sure requests are 50/50