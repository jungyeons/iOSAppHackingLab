# GitHub Actions Demo Artifacts

The `Self Check` workflow uploads public-safe demo media as a GitHub Actions artifact on every push and pull request.

## Artifact Contents

Artifact name: `iosapphackinglab-demo-media`

Included files:

- `artifacts/*.png`
- `artifacts/*.gif`
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
