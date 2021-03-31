#!/bin/bash

# Copyright © 2017 Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
IFS=$'\n\t'
set -eou pipefail

OFFSET=${2:-90}
LIMIT=${3:-0}

re='^[0-9]+$'
if [[ "$#" -lt 1 || "${1}" == '-h' || "${1}" == '--help' ]]; then
  cat >&2 <<"EOF"
gcr-clean.sh cleans up tagged or untagged images pushed before specified date
for a given repository (an image name without a tag/digest). But keep in repo LIMIT count of lates images.
USAGE:
  gcr-clean.sh REPOSITORY DAYS LIMIT
EXAMPLE
  gcr-clean.sh gcr.io/directory/my-app 120 40
  would clean up everything under the gcr.io/directory/my-app repository
  pushed before 120 days ago ( Default 90 days ), but keep last 40 images.
EOF
   exit 1

elif ! [[ $OFFSET =~ $re ]]; then
   echo "error: DAYS=$OFFSET is not a number" >&2; 
   exit 1

elif ! [[ $LIMIT =~ $re ]]; then
   echo "error: LIMIT=$LIMIT is not a number" >&2; 
   exit 1   
fi

main(){
  local C=0
  IMAGE="${1}"
  # DATE=`date -j -v-${OFFSET}d +"%Y-%m-%d"` # BSD format
  DATE=`date +%Y-%m-%d -d "$OFFSET day ago"` # GNU format
  echo "Images ${IMAGE} older $DATE will be cleaned except last $LIMIT"
  COUNT_IMG=`gcloud container images list-tags ${IMAGE} | wc -l | tr -d ' '`
  if [[ $((COUNT_IMG-1-LIMIT)) -le 0 ]]; then
    echo "Number of images ${IMAGE} = $((COUNT_IMG-1)), less or equal than limit ${LIMIT}"
    echo "Nothing to do"
    exit 0
  fi
  for digest in $(gcloud container images list-tags ${IMAGE} --limit=$((COUNT_IMG-LIMIT-1)) --sort-by=TIMESTAMP --filter="timestamp.datetime < '${DATE}'" --format='get(digest)'); do
    (
      set -x
      gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
    )
    echo ${digest}
    let C=C+1
  done
  echo "Deleted ${C} images in ${IMAGE}." >&2
}

main "$@"

