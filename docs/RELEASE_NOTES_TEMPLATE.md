# Release Notes Template

Use this template when drafting a GitHub release for the public portfolio repository.

Generate a ready-to-use GitHub release draft from the current media manifest:

```bash
swift tools/generate-media-manifest.swift
swift tools/generate-release-draft.swift --version v0.1.0 --date 2026-04-28
```

## <version> - <date>

### Highlights

- <short feature or evidence update>
- <short security-learning improvement>
- <short documentation or CI improvement>

### Demo Media Manifest Summary

- Manifest: [`artifacts/media-manifest.json`](../artifacts/media-manifest.json)
- GitHub Actions artifact: `iosapphackinglab-demo-media`
- Checked-in public media: 23 files
- PNG screenshots: 16
- GIF demos: 7
- Total public media bytes: 15,494,605
- Validation command: `swift tools/verify-demo-media.swift`
- Manifest command: `swift tools/generate-media-manifest.swift`
- Release draft command: `swift tools/generate-release-draft.swift --version v0.1.0 --date 2026-04-28`

Update the counts above after regenerating `artifacts/media-manifest.json`.

### New Or Updated Evidence

- API client mock flow GIF: `artifacts/ios-simulator-entitlement-api-client-mock.gif`
- Captioned API client mock flow GIF: `artifacts/ios-simulator-entitlement-api-client-mock-captioned.gif`
- API client mock result screenshot: `artifacts/ios-simulator-entitlement-api-client-mock.png`
- Sanitized report export history screenshot: `artifacts/ios-simulator-report-export-history.png`
- Files app narrated reopen GIF: `artifacts/ios-simulator-report-export-files-reopen-narrated.gif`

### Safety Notes

- Demo media must stay scoped to `com.jungyeons.iosapphackinglab`.
- Release notes should not include raw simulator containers, private notes, real credentials, or unredacted local paths.
- Run the public-doc sensitive string scan from the README before publishing.
