# Contributing

Thanks for wanting to improve the BinDist docs!

## The short version

Open a pull request against `main` and we'll take a look. That's it. There's no template, no issue-first requirement, no CLA.

For typo fixes and small wording changes, you can edit the file directly on GitHub and let it create the PR for you. For anything larger, it's worth previewing locally first (see below).

## Previewing locally

Requires Python 3.10+.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

mkdocs serve           # live preview at http://127.0.0.1:8000
mkdocs build --strict  # produce ./site/, fail on broken links
```

`mkdocs serve` watches the `docs/` directory and reloads the browser on save. `mkdocs build --strict` is what CI runs on every PR — if it fails locally it will fail in CI, so it's worth running before pushing.

## What lives where

- `docs/` — the Markdown sources that become the website. **Anything you add here will be published.**
- `mkdocs.yml` — site config and navigation. If you add a new page, add it to the `nav:` block too, otherwise it won't appear in the sidebar.
- `requirements.txt` — pinned mkdocs + theme versions.
- `README.md`, `CONTRIBUTING.md`, `DEPLOYMENT.md` — repo-level docs (not published to the website).

## What we look at in review

Roughly, in order:

1. **Does it build?** CI runs `mkdocs build --strict`, which fails on broken internal links. Green CI is the bar for "ready to look at".
2. **Is the content accurate?** We'll sanity-check anything that touches API behavior or SDK usage against the actual code.
3. **Does it fit the existing structure?** New pages should land under one of the four top-level sections (Getting Started, API Reference, SDKs, Guides) and be added to `nav:`.

That's the whole process. If you're unsure whether a change makes sense, open the PR anyway — it's much easier to discuss against a concrete diff.
