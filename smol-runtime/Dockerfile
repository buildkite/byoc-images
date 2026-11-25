# syntax=docker/dockerfile:1
FROM ubuntu:24.04@sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b

ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/buildkite/byoc-images" \
      org.opencontainers.image.revision="$SOURCE_REVISION" \
      com.buildkite.byoc.agent-revision="0ae35f60606b8878f4d2f83011e0a10666443385" \
      com.buildkite.byoc.qualification="lab-only"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       bash ca-certificates curl docker.io git iptables openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/buildkite /buildkite/builds /buildkite/job-context

ADD --chmod=0755 --checksum=sha256:42d81ef0a96fc4b006cdc7d3bc49b2a8afef13115dfb20b4da40f70a33f1f928 \
    https://download.buildkite.com/agent/experimental/4.12.0.15529/buildkite-agent-linux-amd64 /usr/bin/buildkite-agent

RUN buildkite-agent start --help | grep -F -- --executor-docker-image \
    && sha256sum /usr/bin/buildkite-agent > /etc/buildkite/agent.sha256 \
    && printf 'image=smol-runtime\nsource_revision=%s\nagent_revision=0ae35f60606b8878f4d2f83011e0a10666443385\nqualification=lab-only\n' \
       "$SOURCE_REVISION" > /etc/buildkite/byoc-image

CMD ["/usr/bin/dockerd", "--host=unix:///var/run/docker.sock", "--storage-driver=overlay2"]
