#!/bin/zsh

export KNATIVE_SETUP_KAFKA_BOOTSTRAP_NAME=kafka

#strimzi kafka
#kubectl create namespace kafka
#kubectl create -f 'https://strimzi.io/install/latest?namespace=default' -n default
#kubectl apply -f https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml -n default
#kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n default

#bitnami kafka
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
./setup-kafka-stuff.sh