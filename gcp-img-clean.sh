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

OFFSET=${3:-90}
LIMIT=${4:-0}

re='^[0-9]+$'
if [[ "$#" -lt 2 || "${1}" == '-h' || "${1}" == '--help' ]]; then
  cat >&2 <<"EOF"
gcp-img-clean.sh cleans up VM instance images created before specified date and Family filter
for a given project. But keep in repo LIMIT count of latest images.
USAGE:
  gcp-img-clean.sh PROJECT 'FILTER' DAYS LIMIT
EXAMPLE
  gcp-img-clean.sh my-gcp-project 'my-app-image-(dev|prod)' 120 40
  would clean up VM images under the my-gcp-project project 
  created before 120 days ago ( Default 90 days ), but keep last 40 images.
  !!! Pay attention FILTER should be set up in quotas
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

  PROJECT="${1}"
  FILTER="${2}"
  echo "Images for project $PROJECT older than $OFFSET  days will be cleaned except last $LIMIT"
  COUNT_IMG=`gcloud compute images list --project $PROJECT --filter="family~'${FILTER}'" --sort-by=creationTimestamp --format="get(name)" | wc -l`
  if [[ $((COUNT_IMG-LIMIT)) -le 0 ]]; then
    echo "Number of images in ${PROJECT} = ${COUNT_IMG}, less or equal than limit ${LIMIT}"
    echo "Nothing to do"
    exit 0
  fi
  echo "${COUNT_IMG} images founded"
  TERMINATION_LIST=$(gcloud compute images list --project ${PROJECT} --filter="family~'${FILTER}' AND creationTimestamp < -P${OFFSET}D" --sort-by=creationTimestamp  --format="get(name)" --limit $((COUNT_IMG-LIMIT))| awk '{ print $1 " "}' | tr -d "\n")
  TERMINATION_COUNT=`wc -w <<< "$TERMINATION_LIST"`
  if [[ $((TERMINATION_COUNT)) -eq 0 ]]; then
    echo "There's no any old images"
    exit 0
  fi
  echo "Following images will be terminated"
  echo $TERMINATION_LIST
  #gcloud compute images delete --project ${PROJECT} --quiet "${TERMINATION_LIST}"
  gcloud compute images delete --project ${PROJECT} --quiet $(gcloud compute images list --project ${PROJECT} --filter="family~'${FILTER}' AND creationTimestamp < -P${OFFSET}D" --sort-by=creationTimestamp  --uri --limit $((COUNT_IMG-LIMIT)) )
  echo "Deleted $TERMINATION_COUNT images in project ${PROJECT}." >&2
}

main "$@"
