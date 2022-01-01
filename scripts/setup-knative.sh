#!/bin/zsh

#if [ "$(kubectl get pod kafka-0 --template={{.status.phase}})" != "Running" ]; then
#  helm repo add bitnami https://charts.bitnami.com/bitnami
#  helm install kafka bitnami/kafka
#fi
#
#until [ "$(kubectl get pod kafka-0 --template={{.status.phase}})" = "Running" ];
#do
#  echo "Waiting for kafka......"
#  sleep 15s
#done

# install knative operator
kubectl apply -f https://github.com/knative/operator/releases/download/knative-v1.1.0/operator.yaml

# install serving
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: knative-serving
---
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
EOF

# install kourier
cat <<EOF | kubectl apply -f -
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  ingress:
    kourier:
      enabled: true
  config:
    network:
      ingress.class: "kourier.ingress.networking.knative.dev"
EOF

# install knative eventing
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: knative-eventing
  labels:
    app.kubernetes.io/name: knative-eventing
---
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeEventing
metadata:
  name: knative-eventing
  namespace: knative-eventing
spec:
EOF

# set default domain
exit 0;
cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  127.0.0.1.nip.io: ""
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: knative-serving
    app.kubernetes.io/version: 1.1.0
    serving.knative.dev/release: v1.1.0
  name: config-domain
  namespace: knative-serving
EOF