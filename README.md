# byoc-images
Lab-only BYOC microVM and agent-free base container images; not for production or customer defaults

Buildkite Pipelines builds and publishes Linux amd64 images to the public
`packages.buildkite.com/buildkite/byoc` OCI registry. Only the webhook-triggered
`main` publish job can write, using short-lived OIDC. There is no Namespace
deployment trigger or GitHub Actions publisher.

| Input | Image | Purpose |
| --- | --- | --- |
| `providers/e2b/Dockerfile` | `e2b-runtime` | E2B import/boot fixture with Docker Engine and a source-pinned experimental host agent |
| `base/Dockerfile` | `base` | Hosted-toolset-derived job container with Docker client tools, without the agent |

Use the immutable image reference in the build's `artifacts/e2b-runtime.json`
or `artifacts/base.json`, not the commit tag, for consumers. Each records the
source revision, platform and SHA-256 of `/etc/buildkite/byoc-image`.
The build also records the host agent binary hash and experimental command help.

The host agent supplies its own binary read-only at `/bin/buildkite-agent` in the job container. No
agent is registered and no job/provider credentials are baked into either image.
E2B template preparation starts the uncredentialed Docker service idempotently
with `systemctl start docker.service`, checks `docker info`, and pulls the pinned
default base image before capturing warm state. E2B already starts system services;
launching a second `dockerd` conflicts with the running daemon. Preparation must
not start a registered agent.

The experimental agent uses native `docker-bootstrap --image-from-job
--mount-docker-socket --docker-cli-plugins /usr/local/lib/docker/cli-plugins`.
The server must resolve step, pipeline, queue, then default image into the API
job's `BUILDKITE_IMAGE`; an ambient host environment value does not select it.
The VM supplies static Docker CLI/plugins read-only to the job container, which
runs bootstrap. The registered agent stays outside. Docker socket access grants
VM control, so each VM must run one job and be destroyed after it.

These are lab candidates. Unchanged Node.js and real Compose acceptance against
each published VM digest are required; local tests and an older import-only
image do not qualify a new release. Do not route customer or production jobs to
these lab images.
