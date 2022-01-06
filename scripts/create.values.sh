#!/usr/bin/env bash

# create the values.yml for the given helm chart, tag/version
tag=$1

deployDir="./charts"
template="$deployDir/values.template.yaml"
values="${deployDir}/values.yaml"
brokerUrl="$(kubectl get service kafka --template={{.spec.clusterIP}}):9092"

sed -e "s/\$tag/${tag}/" \
    "${template}" > "${values}"

sed -e "s/\$broker_url/${brokerUrl}/" \
    "${template}" > "${values}"

echo "Wrote new chart values to $deployDir/values.yaml"
cat $deployDir/values.yaml

# Creating the Chart.yaml with the application version
chartTemplate="$deployDir/Chart.template.yaml"
chartValue="${deployDir}/Chart.yaml"

appVer=$(awk '/appVersion/ {split($0,a,"="); print a[2]}' gradle.properties | xargs)

sed -e "s/\$appVer/${appVer}/" \
    "${chartTemplate}" > "${chartValue}"

echo "Wrote new chart values to $deployDir/Chart.yaml"
cat $deployDir/Chart.yaml
