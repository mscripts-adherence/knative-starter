#!/bin/bash

# install various eventing kafka modules (all are not likely needed)
kubectl apply --filename https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.0.5/eventing-kafka.yaml
kubectl apply --filename https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.0.5/eventing-kafka-controller.yaml
kubectl apply --filename https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.0.5/eventing-kafka-broker.yaml
kubectl apply --filename https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.0.5/eventing-kafka-sink.yaml

# TODO: is a wait needed here?
kubectl api-resources | grep broker

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-broker-config
  namespace: knative-eventing
data:
  # Number of topic partitions
  default.topic.partitions: "10"
  # Replication factor of topic messages.
  default.topic.replication.factor: "1"
  # A comma separated list of bootstrap servers. (It can be in or out the k8s cluster)
  bootstrap.servers: "$(kubectl get service $KNATIVE_SETUP_KAFKA_BOOTSTRAP_NAME --template={{.spec.clusterIP}}):9092"
EOF

## TODO: is a wait needed here?  We are dependent on kafka being up

# add kafka broker
cat <<EOF | kubectl apply -f -                              
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    # case-sensitive
    eventing.knative.dev/broker.class: Kafka
  name: kafka-broker
  namespace: default
spec:
  # Configuration specific to this broker.
  config:
    apiVersion: v1
    kind: ConfigMap
    name: kafka-broker-config
    namespace: knative-eventing
EOF

# set kafka broker as default for knative ns
#cat <<EOF | kubectl apply -f -
#apiVersion: v1
#kind: ConfigMap
#metadata:
#  name: config-br-defaults
#  namespace: knative-eventing
#  labels:
#    eventing.knative.dev/release: devel
#data:
#  # Configures the default for any Broker that does not specify a spec.config or Broker class.
#  default-br-config: |
#    clusterDefault:
#      brokerClass: KafkaBroker
#EOF

# set kafka channel as default for knative ns
#cat <<EOF | kubectl apply -f -
#apiVersion: v1
#kind: ConfigMap
#metadata:
#  name: default-ch-webhook
#  namespace: knative-eventing
#data:
#  default-ch-config: |
#    clusterDefault:
#      apiVersion: messaging.knative.dev/v1alpha1
#      kind: InMemoryChannel
#    namespaceDefaults:
#      knative-starter:
#        apiVersion: messaging.knative.dev/v1alpha1
#        kind: KafkaChannel
#        spec:
#          numPartitions: 1
#          replicationFactor: 1
#EOF

# set up a channel
#cat <<EOF | kubectl apply -f -
#apiVersion: messaging.knative.dev/v1
#kind: Channel
#metadata:
#  name: knative-starter-channel
#EOF

#cat <<EOF | kubectl apply -f -
#apiVersion: eventing.knative.dev/v1alpha1
#kind: KafkaSink
#metadata:
#  name: kafka-sink-sampletopic
#  namespace: default
#spec:
#  topic: sampletopic
#  bootstrapServers:
#    - $(kubectl get service kafka --template={{.spec.clusterIP}}):9092
#EOF
