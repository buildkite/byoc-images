# syntax=docker/dockerfile:1
FROM docker:29-cli@sha256:34507eb5069d8be82c95dd3b6987d4250fd5fee49b82e2509b7d7a7030740d6d AS docker
FROM buildkite/agent-base:ubuntu-noble-hosted@sha256:75780317b9325425dd6721f5e5f1339722aee3a3821d091d1cd61013ff340ea2

ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/buildkite/byoc-images" \
      org.opencontainers.image.revision="$SOURCE_REVISION" \
      com.buildkite.byoc.qualification="lab-only"

COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/
RUN ! command -v buildkite-agent \
    && node --version && git --version && git lfs version && aws --version \
    && docker --version && docker compose version && docker buildx version \
    && mkdir -p /etc/buildkite \
    && printf 'image=base\nsource_revision=%s\nqualification=lab-only\n' \
       "$SOURCE_REVISION" > /etc/buildkite/byoc-image

CMD ["/bin/bash"]
