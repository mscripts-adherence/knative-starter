#!/usr/bin/env bash

# install bitnami kafka
if [ "$(kubectl get pod kafka-0 --template={{.status.phase}})" != "Running" ]; then
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm install kafka bitnami/kafka
fi

echo "waiting up to 5 minutes for kafka to start"
kubectl wait --for=condition=ready pod/kafka-0 --timeout=5m

./setup-knative.sh
./setup-kafka-knative.sh