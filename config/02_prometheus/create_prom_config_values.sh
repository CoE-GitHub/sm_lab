#!/bin/bash

cat << EOF > values_prometheus.yaml
rbac:
  create: true
alertmanager:
  enabled: false
kubeStateMetrics:
  enabled: false
nodeExporter:
  enabled: false
pushgateway:
  enabled: false
server:
  statefulSet:
    enabled: true
  persistentVolume:
    size: 25Gi
  sidecarContainers:
    - name: sidecar
      image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:0.7.0
      args:
      - "--stackdriver.project-id=${GCP_PROJECT_ID}"
      - "--prometheus.wal-directory=/data/wal"
      - "--prometheus.api-address=http://127.0.0.1:9090"
      - "--stackdriver.kubernetes.location=${GCP_REGION}"
      - "--stackdriver.kubernetes.cluster-name=${GCP_KUBE_CLUSTER}"
      ports:
      - name: sidecar
        containerPort: 9091
      volumeMounts:
      - name: storage-volume
        mountPath: /data

  extraSecretMounts:
    - name: istio-certs
      mountPath: /etc/istio-certs
      subPath: ""
      secretName: istio.prometheus-server
      readOnly: true

####
  global:
    scrape_interval: 60s
    scrape_timeout: 15s
    evaluation_interval: 1m
####
## Prometheus server ConfigMap entries
####
serverFiles:
  rules: {}
  prometheus.yml:
    rule_files:
      - /etc/config/rules
      - /etc/config/alerts
 
    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090
 
      - job_name: 'kubernetes-service-endpoints'
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (https?)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: \$1:\$2
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name
          - source_labels: [__meta_kubernetes_pod_node_name]
            action: replace
            target_label: kubernetes_node
 
      - job_name: 'kubernetes-services'
        metrics_path: /probe
        params:
          module: [http_2xx]
        kubernetes_sd_configs:
          - role: service
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
            action: keep
            regex: true
          - source_labels: [__address__]
            target_label: __param_target
          - target_label: __address__
            replacement: blackbox
          - source_labels: [__param_target]
            target_label: instance
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: kubernetes_name
 
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: \$1:\$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name

#################
### ISTIO
#################
      - job_name: 'istio-mesh'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-telemetry;prometheus

      # Scrape config for envoy stats
      - job_name: 'envoy-stats'
        metrics_path: /stats/prometheus
        kubernetes_sd_configs:
        - role: pod

        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_container_port_name]
          action: keep
          regex: '.*-envoy-prom'
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:15090
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: pod_name

        metric_relabel_configs:
        # Exclude some of the envoy metrics that have massive cardinality
        # This list may need to be pruned further moving forward, as informed
        # by performance and scalability testing.
        - source_labels: [ cluster_name ]
          regex: '(outbound|inbound|prometheus_stats).*'
          action: drop
        - source_labels: [ tcp_prefix ]
          regex: '(outbound|inbound|prometheus_stats).*'
          action: drop
        - source_labels: [ listener_address ]
          regex: '(.+)'
          action: drop
        - source_labels: [ http_conn_manager_listener_prefix ]
          regex: '(.+)'
          action: drop
        - source_labels: [ http_conn_manager_prefix ]
          regex: '(.+)'
          action: drop
        - source_labels: [ __name__ ]
          regex: 'envoy_tls.*'
          action: drop
        - source_labels: [ __name__ ]
          regex: 'envoy_tcp_downstream.*'
          action: drop
        - source_labels: [ __name__ ]
          regex: 'envoy_http_(stats|admin).*'
          action: drop
        - source_labels: [ __name__ ]
          regex: 'envoy_cluster_(lb|retry|bind|internal|max|original).*'
          action: drop

      - job_name: 'istio-policy'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-policy;http-monitoring

      - job_name: 'istio-telemetry'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-telemetry;http-monitoring

      - job_name: 'pilot'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-pilot;http-monitoring

      - job_name: 'galley'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-galley;http-monitoring

      - job_name: 'citadel'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istio-citadel;http-monitoring

      - job_name: 'kubernetes-pods-istio-secure'
        scheme: https
        tls_config:
          ca_file: /etc/istio-certs/root-cert.pem
          cert_file: /etc/istio-certs/cert-chain.pem
          key_file: /etc/istio-certs/key.pem
          insecure_skip_verify: true  # prometheus does not support secure naming.
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        # sidecar status annotation is added by sidecar injector and
        # istio_workload_mtls_ability can be specifically placed on a pod to indicate its ability to receive mtls traffic.
        - source_labels: [__meta_kubernetes_pod_annotation_sidecar_istio_io_status, __meta_kubernetes_pod_annotation_istio_mtls]
          action: keep
          regex: (([^;]+);([^;]*))|(([^;]*);(true))
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
          action: drop
          regex: (http)
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__]  # Only keep address that is host:port
          action: keep    # otherwise an extra target with ':443' is added for https scheme
          regex: ([^:]+):(\d+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: \$1:\$2
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: pod_name


EOF
###
