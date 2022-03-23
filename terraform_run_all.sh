#!/bin/bash

TAG=$(cat .terraform-version)
ACTION="$1"

for folder in *; do
  if [ -d "$folder" ]; then
    echo "🔬 folder: $folder in under terraform: $ACTION action"
    cd "$folder" || exit
    docker run -v "$(pwd):/tmp" -w /tmp "hashicorp/terraform:$TAG" "$ACTION"
    cd ..
  fi
done
