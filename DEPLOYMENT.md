# Deployment

How [docs.bindist.eu](https://docs.bindist.eu) gets built and published. If you only want to edit content, see [CONTRIBUTING.md](CONTRIBUTING.md) instead.

## Branching model

There is no separate dev environment. `main` is what's live at docs.bindist.eu. For work-in-progress documentation, branch off `main`, iterate, and merge when ready — the build workflow runs on every PR and branch push so you'll catch broken links before merging.

## Continuous deployment

Two workflows live under `.github/workflows/`:

- **build.yml** — runs on every PR and on pushes to non-`main` branches. Installs MkDocs, runs `mkdocs build --strict` (broken internal links fail CI), uploads `site/` as an artifact for inspection.
- **deploy.yml** — runs on every push to `main` and on `workflow_dispatch`. Builds, then syncs `site/` to the Scaleway Object Storage bucket using the AWS CLI against Scaleway's S3-compatible endpoint. Cache headers: 300s for HTML, one year for hashed assets, one hour for everything else.

A `concurrency` group prevents two deploys from running at once.

The bucket sits behind Scaleway Edge Services, which is what `docs.bindist.eu` actually resolves to. The deploy workflow does not currently purge the edge cache after a sync — edits to existing pages will be served stale until the edge TTL expires. Wiring up a purge step is tracked as a TODO at the top of `deploy.yml`.

### Required secrets

Defined under **Settings → Secrets and variables → Actions**:

| Secret              | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `SCW_ACCESS_KEY`    | Scaleway API access key with write access on the docs bucket                |
| `SCW_SECRET_KEY`    | Scaleway API secret key                                                     |
| `SCW_REGION`        | Scaleway region, e.g. `fr-par`                                              |
| `SCW_S3_ENDPOINT`   | S3-compatible endpoint URL, e.g. `https://s3.fr-par.scw.cloud`              |
| `SCW_DOCS_BUCKET`   | Bucket name (e.g. `docs.bindist.eu`)                                        |

Scaleway IAM does not currently support GitHub OIDC, so the workflow uses static API keys. Scope the key to a dedicated IAM application that only has object-write permission on the docs bucket.

## Manual deployment

`deploy-docs.sh` does the same thing as the workflow from your laptop. It expects the same five environment variables and is intended as a fallback when the workflow is unavailable.

```bash
export SCW_ACCESS_KEY=...
export SCW_SECRET_KEY=...
export SCW_REGION=fr-par
export SCW_S3_ENDPOINT=https://s3.fr-par.scw.cloud
export SCW_DOCS_BUCKET=docs.bindist.eu

./deploy-docs.sh
```
