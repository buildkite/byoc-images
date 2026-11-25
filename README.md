# byoc-images
Lab-only BYOC microVM and agent-free base container images; not for production or customer defaults

Buildkite Pipelines builds and publishes Linux amd64 images to the public
`packages.buildkite.com/buildkite/byoc` OCI registry. Only the webhook-triggered
`main` publish job can write, using short-lived OIDC. There is no Namespace
deployment trigger or GitHub Actions publisher.

| Input | Image | Purpose |
| --- | --- | --- |
| `providers/e2b/Dockerfile` | `e2b-runtime` | E2B import/boot fixture with Docker Engine and a source-pinned experimental host agent |
| `smol-runtime/Dockerfile` | `smol-runtime` | Smol Machines guest with Docker Engine and a pinned published Linux agent |
| `base/Dockerfile` | `base` | Hosted-toolset-derived job container with Docker client tools, without the agent |

Flagged development consumers follow `e2b-runtime:latest` and `base:latest`.
The publisher updates the base first, then the runtime. For reproducible qualification,
use the immutable image reference in the build's `artifacts/<image>.json`.
Each records the source revision, platform and SHA-256 of `/etc/buildkite/byoc-image`.
The build also records the host agent binary hash and experimental command help.

The host agent supplies its own binary read-only at `/buildkite-agent/bin/buildkite-agent` in the job container. No
agent is registered and no job/provider credentials are baked into the images.
E2B template preparation calls image-owned `/bin/start` and `/bin/ready`.
They start the uncredentialed Docker service idempotently with `systemctl start docker.service`,
check `docker info`, and pull `base:latest` before capturing warm state. E2B already starts system services;
launching a second `dockerd` conflicts with the running daemon. Preparation must
not start a registered agent.

For Smol Machines, `smol-runtime` is the OCI guest image; `base` is still a job
container image. The guest runs `dockerd` without systemd. Keep Docker state on
guest storage, not the guest's root overlay or the machine host's Docker socket.
For local `smolvm`, use a `docker save` archive if native registry import fails.

The experimental agent uses `start --experiment docker-executor --executor docker`
with the shared base as `--executor-docker-image`. The server resolves
step, pipeline, queue, then default image into the typed Agent API `image` field;
`BUILDKITE_IMAGE` cannot select it. The job image supplies its shell, Git, CA
certificates and any Docker CLI/plugins it needs. The registered agent stays
outside. Docker socket access defaults on and grants VM control, so each VM
must run one job and be destroyed after it. At the pinned agent revision,
blocking signature verification rejects per-job images because image selection
is not yet covered by the signed-step protocol.

These are lab candidates. Unchanged Node.js and real Compose acceptance against
each published VM digest are required; local tests and an older import-only
image do not qualify a new release. Do not route customer or production jobs to
these lab images.
