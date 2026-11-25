#!/usr/bin/env bash
set -euo pipefail

registry=packages.buildkite.com/buildkite/byoc
tag="lab-${BUILDKITE_COMMIT}"
mkdir -p artifacts
export DOCKER_CONFIG
DOCKER_CONFIG=$(mktemp -d)
trap 'rm -rf "$DOCKER_CONFIG"' EXIT

for image in base e2b-runtime; do
  dockerfile="$image/Dockerfile"
  ref="$registry/$image:$tag"
  latest_ref="$registry/$image:latest"

  echo "--- Build $image"
  docker buildx build --platform linux/amd64 --provenance=false --load \
    --build-arg "SOURCE_REVISION=$BUILDKITE_COMMIT" \
    --tag "$ref" --tag "$latest_ref" --file "$dockerfile" .

  docker run --rm --entrypoint sha256sum "$ref" /etc/buildkite/byoc-image \
    > "artifacts/$image-marker.sha256"
  docker run --rm --entrypoint cat "$ref" /etc/buildkite/byoc-image \
    > "artifacts/$image-marker.txt"
  if [[ "$image" == e2b-runtime ]]; then
    docker run --rm --entrypoint bash "$ref" -ec \
      'test -x /bin/start; test -x /bin/ready; bash -n /bin/start /bin/ready'
    docker run --rm --entrypoint buildkite-agent "$ref" start --help \
      > artifacts/docker-executor-help.txt
    grep -F -- --executor-docker-image artifacts/docker-executor-help.txt
    docker run --rm --entrypoint cat "$ref" /etc/buildkite/agent.sha256 \
      > artifacts/agent.sha256
  else
    docker run --rm --entrypoint bash "$ref" -ec \
      'if command -v buildkite-agent; then exit 1; fi; node --version; git lfs version; aws --version; docker compose version; docker buildx version' \
      > artifacts/base-tools.txt
  fi

  echo "--- Publish $image with short-lived OIDC"
  buildkite-agent oidc request-token \
    --audience "https://$registry" --lifetime 300 \
    | docker login "$registry" --username buildkite --password-stdin
  docker push "$ref"
  docker push "$latest_ref"
  digest_ref=$(docker image inspect "$ref" --format '{{index .RepoDigests 0}}')
  jq -n --arg image "$image" --arg reference "$digest_ref" \
    --arg source_revision "$BUILDKITE_COMMIT" \
    --arg marker_path /etc/buildkite/byoc-image \
    --arg marker_sha256 "$(cut -d ' ' -f1 "artifacts/$image-marker.sha256")" \
    '{image:$image,reference:$reference,source_revision:$source_revision,platform:"linux/amd64",marker_path:$marker_path,marker_sha256:$marker_sha256}' \
    > "artifacts/$image.json"
  cat "artifacts/$image.json"
done
