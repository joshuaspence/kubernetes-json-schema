#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

function crd_to_json_schema() {
  local api_version document group input kind version

  echo "Processing ${1}..."
  input="input/${1}.yaml"
  curl --silent --show-error "${@:2}" > "${input}"

  for document in $(seq 0 $(($(yq read --collect --doc '*' --length "${input}") - 1))); do
    api_version=$(yq read --doc "${document}" "${input}" apiVersion | cut --delimiter=/ --fields=2)
    kind=$(yq read --doc "${document}" "${input}" spec.names.kind | tr '[:upper:]' '[:lower:]')
    group=$(yq read --doc "${document}" "${input}" spec.group | cut --delimiter=. --fields=1)

    case "${api_version}" in
      v1beta1)
        version=$(yq read --doc "${document}" "${input}" spec.version)
        yq read --doc "${document}" --prettyPrint --tojson "${input}" spec.validation.openAPIV3Schema | write_schema "${kind}-${group}-${version}.json"
        ;;

      v1)
        for version in $(yq read --doc "${document}" "${input}" spec.versions.*.name); do
          yq read --doc "${document}" --prettyPrint --tojson "${input}" "spec.versions.(name==${version}).schema.openAPIV3Schema" | write_schema "${kind}-${group}-${version}.json"
        done
        ;;

      *)
        echo "Unknown API version: ${version}" >&2
        return 1
        ;;
    esac
  done
}

function write_schema() {
  sponge "master-standalone/${1}"
  jq 'def strictify: . + if .type == "object" and has("properties") then {additionalProperties: false} + {properties: (({} + .properties) | map_values(strictify))} else null end; . * {properties: {spec: .properties.spec | strictify}}' "master-standalone/${1}" | sponge "master-standalone-strict/${1}"
}

crd_to_json_schema cert-manager https://raw.githubusercontent.com/jetstack/cert-manager/master/deploy/crds/crd-clusterissuers.yaml
crd_to_json_schema helm-operator https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
crd_to_json_schema prometheus-operator https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/example/prometheus-operator-crd/monitoring.coreos.com_{alertmanagers,podmonitors,probes,prometheuses,prometheusrules,servicemonitors,thanosrulers}.yaml
crd_to_json_schema argo-rollouts https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

