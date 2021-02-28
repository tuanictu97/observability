#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/node-exporter
mkdir -p manifests/kube-state-metrics
mkdir -p manifests/prometheus-operator/setup
mkdir -p manifests/prometheus
mkdir -p manifests/alertmanager
mkdir -p manifests/grafana
mkdir -p manifests/kubernetes

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests \
--ext-str namespace=${NAMESPACE:-cluster-monitoring} \
--ext-code is_preview_env=${IS_PREVIEW_ENV:-false} \
"${1}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}


# Move Prometheus-Operator CRDs to a diferent directory
if [[ ${IS_PREVIEW_ENV:-false} == false ]]; then
  mv manifests/prometheus-operator/*CustomResourceDefinition.yaml manifests/prometheus-operator/setup/
fi

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization