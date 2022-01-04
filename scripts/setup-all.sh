#!/bin/zsh

# install bitnami kafka
if [ "$(kubectl get pod kafka-0 --template={{.status.phase}})" != "Running" ]; then
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm install kafka bitnami/kafka
fi
until [ "$(kubectl get pod kafka-0 --template={{.status.phase}})" = "Running" ];
do
  echo "Waiting for kafka......"
  sleep 15s
done

./setup-knative.sh
./setup-kafka-knative.sh