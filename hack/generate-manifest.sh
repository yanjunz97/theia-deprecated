#!/usr/bin/env bash

# Copyright 2022 Antrea Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eo pipefail

function echoerr {
    >&2 echo "$@"
}

_usage="Usage: $0 [--mode (dev|release)] [--keep] [--help|-h]
Generate a YAML manifest for the Clickhouse-Grafana Flow-visibility Solution, using Helm, and
print it to stdout.
        --mode (dev|release)  Choose the configuration variant that you need (default is 'dev')

This tool uses Helm 3 (https://helm.sh/) to generate manifests for Antrea. You can set the HELM
environment variable to the path of the helm binary you want us to use. Otherwise we will download
the appropriate version of the helm binary and use it (this is the recommended approach since
different versions of helm may create different output YAMLs)."

function print_usage {
    echoerr "$_usage"
}

function print_help {
    echoerr "Try '$0 --help' for more information."
}

MODE="dev"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --mode)
    MODE="$2"
    shift 2
    ;;
    -h|--help)
    print_usage
    exit 0
    ;;
    *)    # unknown option
    echoerr "Unknown option $1"
    exit 1
    ;;
esac
done

if [ "$MODE" != "dev" ] && [ "$MODE" != "release" ]; then
    echoerr "--mode must be one of 'dev' or 'release'"
    print_help
    exit 1
fi

if [ "$MODE" == "release" ] && [ -z "$IMG_NAME" ]; then
    echoerr "In 'release' mode, environment variable IMG_NAME must be set"
    print_help
    exit 1
fi

if [ "$MODE" == "release" ] && [ -z "$IMG_TAG" ]; then
    echoerr "In 'release' mode, environment variable IMG_TAG must be set"
    print_help
    exit 1
fi

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Avoid potential Helm warnings about invalid permissions for Kubeconfig file.
# The Kubeconfig does not matter for "helm template".
unset KUBECONFIG

source $THIS_DIR/verify-helm.sh

if [ -z "$HELM" ]; then
    HELM="$(verify_helm)"
elif ! $HELM version > /dev/null 2>&1; then
    echoerr "$HELM does not appear to be a valid helm binary"
    print_help
    exit 1
fi

TMP_DIR=$(mktemp -d $THIS_DIR/../build/yamls/chart-values.XXXXXXXX)

EXTRA_VALUES=""
if [ "$MODE" == "release" ]; then
    EXTRA_VALUES="--set clickhouse.monitorImage.repository=$IMG_NAME,clickhouse.monitorImage.tag=$IMG_TAG"
fi

THEIA_CHART="$THIS_DIR/../build/charts/theia"
$HELM template \
      --namespace flow-visibility \
      $EXTRA_VALUES \
      "$THEIA_CHART"

rm -rf $TMP_DIR
