# GitHub Actions Demo Artifacts

The `Self Check` workflow uploads public-safe demo media as a GitHub Actions artifact on every push and pull request.

## Artifact Contents

Artifact name: `iosapphackinglab-demo-media`

Included files:

- `artifacts/*.png`
- `artifacts/*.gif`
- `artifacts/media-manifest.json`
- `docs/CI_ARTIFACTS.md`
- `docs/SIGNED_ENTITLEMENT_API.md`
- `docs/SAMPLE_STUDY_REPORT.md`
- `docs/REPORT_EXPORT_FLOW.md`

The artifact intentionally excludes simulator containers, generated private notes, raw logs, and local exported Markdown files.

## Dimension Validation

Before upload, the workflow runs:

```bash
swift tools/verify-demo-media.swift
```

The verifier scans `artifacts/*.png` and `artifacts/*.gif`, reads dimensions through ImageIO, rejects empty files, and enforces portrait simulator media. PNG screenshots must be at least `1000x2000`; GIFs must be at least `300x600`.

## Media Manifest

After validation, the workflow runs:

```bash
swift tools/generate-media-manifest.swift
```

The manifest records every public demo media file with path, type, pixel dimensions, byte count, and SHA-256 digest. It is uploaded with the artifact so reviewers can audit exactly which screenshots and GIFs were attached to the CI run.

The README links to the checked-in manifest with the `Demo Media Manifest` badge so the same media inventory is visible from the repository front page and from the Actions artifact.

## Why Upload These

- Screenshots and GIFs stay attached to the exact CI run that validated the code.
- Portfolio reviewers can inspect the same media shown in the README without cloning the repository.
- Pull requests can show whether new UI evidence was updated alongside code changes.
- CI fails early if a screenshot or GIF is missing real simulator-sized pixels.

## Safety Checklist

Before publishing demo media:

- Use `Sanitized report export` for public report examples.
- Redact account, password, token, and local filesystem patterns in notes.
- Keep real simulator app containers and local study notes out of the artifact.
- Run the public-doc scan from the README before pushing.

## Access

Open the GitHub Actions run, then download `iosapphackinglab-demo-media` from the run artifacts section. GitHub expires artifacts according to the workflow retention policy.
