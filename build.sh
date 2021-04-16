#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


function crd_to_json_schema() {
  local api_version crd_group crd_kind crd_version document input kind

  echo "Processing ${1}..."
  input="input/${1}.yaml"
  curl --silent --show-error "${@:2}" > "${input}"

  for document in $(seq 0 $(($(yq eval-all '[.] | length' "${input}") - 1))); do
    api_version=$(yq eval 'select(documentIndex == '"${document}"') | .apiVersion' "${input}" | cut -d / -f 2)
    kind=$(yq eval 'select(documentIndex == '"${document}"') | .kind' "${input}")
    crd_kind=$(yq eval 'select(documentIndex == '"${document}"') | .spec.names.kind' "${input}" | tr '[:upper:]' '[:lower:]')
    crd_group=$(yq eval 'select(documentIndex == '"${document}"') | .spec.group' "${input}" | cut -d . -f 1)

    if [[ "${kind}" != CustomResourceDefinition ]]; then
      continue
    fi

    case "${api_version}" in
      v1beta1)
        crd_version=$(yq eval 'select(documentIndex == '"${document}"') | .spec.version' "${input}")
        yq eval --prettyPrint --tojson 'select(documentIndex == '"${document}"') | .spec.validation.openAPIV3Schema' "${input}" | write_schema "${crd_kind}-${crd_group}-${crd_version}.json"
        ;;

      v1)

        for crd_version in $(yq eval 'select(documentIndex == '"${document}"') | .spec.versions.[].name' "${input}"); do
          yq eval --prettyPrint --tojson 'select(documentIndex == '"${document}"') | .spec.versions.[] | select(.name == "'${crd_version}'") | .schema.openAPIV3Schema' "${input}" | write_schema "${crd_kind}-${crd_group}-${crd_version}.json"
        done
        ;;

      *)
        echo "Unknown API version: ${api_version}" >&2
        return 1
        ;;
    esac
  done
}

function write_schema() {
  sponge "master-standalone/${1}"
  jq 'def strictify: . + if .type == "object" and has("properties") then {additionalProperties: false} + {properties: (({} + .properties) | map_values(strictify))} else null end; . * {properties: {spec: .properties.spec | strictify}}' "master-standalone/${1}" | sponge "master-standalone-strict/${1}"
}

crd_to_json_schema cert-manager-clusterissuers https://raw.githubusercontent.com/jetstack/cert-manager/master/deploy/crds/crd-clusterissuers.yaml
crd_to_json_schema cert-manager-certificates https://raw.githubusercontent.com/jetstack/cert-manager/master/deploy/crds/crd-certificates.yaml
crd_to_json_schema helm-operator https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
crd_to_json_schema kamus-secret https://raw.githubusercontent.com/Soluto/helm-charts/master/charts/kamus/templates/kamussecret-crd.yaml
