# syntax=docker/dockerfile:1
FROM golang:1.27.3-bookworm@sha256:dc0963f32053e4bc451d24d87e3892d42d01021b61f093e98eb95c0352bb84b0 AS agent

ARG AGENT_REVISION=d22cc07ae46ada898c3675dde285d1eec07a1bd9
WORKDIR /src/agent
RUN git init . \
    && git remote add origin https://github.com/buildkite/agent.git \
    && git fetch --depth=1 origin "$AGENT_REVISION" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "$AGENT_REVISION" \
    && scripts/build-binary.sh linux amd64 "byoc-lab-${AGENT_REVISION}" \
    && pkg/buildkite-agent-linux-amd64 docker-bootstrap --help

FROM ubuntu:24.04@sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b

ARG SOURCE_REVISION
ARG AGENT_REVISION=d22cc07ae46ada898c3675dde285d1eec07a1bd9
LABEL org.opencontainers.image.source="https://github.com/buildkite/byoc-images" \
      org.opencontainers.image.revision="$SOURCE_REVISION" \
      com.buildkite.byoc.agent-revision="$AGENT_REVISION" \
      com.buildkite.byoc.qualification="lab-import-only"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       bash ca-certificates curl docker.io docker-buildx docker-compose-v2 \
       git iptables openssh-client sudo \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/buildkite \
    && printf 'image=e2b-runtime\nsource_revision=%s\nagent_revision=%s\nqualification=lab-import-only\n' \
       "$SOURCE_REVISION" "$AGENT_REVISION" > /etc/buildkite/byoc-image \
    && dpkg-query -W > /etc/buildkite/packages.txt

COPY --from=agent /src/agent/pkg/buildkite-agent-linux-amd64 /usr/bin/buildkite-agent
RUN buildkite-agent docker-bootstrap --help >/dev/null \
    && sha256sum /usr/bin/buildkite-agent > /etc/buildkite/agent.sha256 \
    && dockerd --version && docker compose version && docker buildx version

CMD ["dockerd", "--host=unix:///var/run/docker.sock"]
