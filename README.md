# BinDist Documentation

Source for **[docs.bindist.eu](https://docs.bindist.eu)** — the public documentation site for [BinDist](https://bindist.eu), a secure, multi-tenant application distribution system with API key-authenticated downloads, version management, and tier-based access control.

This repo contains the documentation only. For the API itself or the client SDKs, see [related repositories](#related-repositories) below.

## What's in here

The Markdown sources under `docs/` are organized into four sections, all rendered by [MkDocs Material](https://squidfunk.github.io/mkdocs-material/):

- **Getting Started** — quick start and authentication setup for new users.
- **API Reference** — REST API for applications, versions, downloads, and management/admin endpoints.
- **SDKs** — language-specific client documentation.
- **Guides** — task-oriented walkthroughs for uploading applications, managing customers, and backups.

The site navigation in `mkdocs.yml` is the source of truth for what's published and in what order.

## Related repositories

The documentation here covers the BinDist platform as a whole. The client libraries live in their own repos:

- [bindist-api-go](https://github.com/BinDist/bindist-api-go) — Go client
- [bindist-api-javascript](https://github.com/BinDist/bindist-api-javascript) — JavaScript / TypeScript client
- [bindist-api-delphi](https://github.com/BinDist/bindist-api-delphi) — Delphi client
- [bindist-api-python](https://github.com/BinDist/bindist-api-python) — Python client

## Contributing

Spotted a typo, an unclear section, or a missing piece of documentation? Please open a pull request — see [CONTRIBUTING.md](CONTRIBUTING.md) for the (very short) process.

## Deployment

`main` is what's live at docs.bindist.eu. CI/CD details, required secrets, and the manual-deploy fallback are documented in [DEPLOYMENT.md](DEPLOYMENT.md).
