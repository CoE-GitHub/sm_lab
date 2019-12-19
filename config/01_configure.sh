pushd 01_istio_config_gke
./00_init_helm.sh
./01_configure.sh
popd

pushd 02_prometheus
./01_configure.sh
popd

pushd 03_kiali
./01_configure.sh
popd

pushd 04_istio_workload_namespaces
./01_configure.sh
popd

pushd 05_jenkins
./01_configure.sh
popd