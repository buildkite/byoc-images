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

The host agent must supply its own binary read-only to the job container. No
agent is registered and no job/provider credentials are baked into either image.
E2B template preparation must start the uncredentialed Docker daemon and check
`docker info` before capturing warm state; it must not start a registered agent.

The initial agent pin is an import fixture, not a qualified job runtime. It does
not yet implement the full resolved-image, `/bin/buildkite-agent` mount and
job-scoped outer Docker socket contract. Unchanged Node.js and real Compose
acceptance must run separately after that integration. Do not route customer or
production jobs to these lab images.
