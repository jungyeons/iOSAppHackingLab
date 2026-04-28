# Release Notes Template

Use this template when drafting a GitHub release for the public portfolio repository.

## <version> - <date>

### Highlights

- <short feature or evidence update>
- <short security-learning improvement>
- <short documentation or CI improvement>

### Demo Media Manifest Summary

- Manifest: [`artifacts/media-manifest.json`](../artifacts/media-manifest.json)
- GitHub Actions artifact: `iosapphackinglab-demo-media`
- Checked-in public media: 22 files
- PNG screenshots: 16
- GIF demos: 6
- Total public media bytes: 15,058,831
- Validation command: `swift tools/verify-demo-media.swift`
- Manifest command: `swift tools/generate-media-manifest.swift`

Update the counts above after regenerating `artifacts/media-manifest.json`.

### New Or Updated Evidence

- API client mock flow GIF: `artifacts/ios-simulator-entitlement-api-client-mock.gif`
- API client mock result screenshot: `artifacts/ios-simulator-entitlement-api-client-mock.png`
- Sanitized report export history screenshot: `artifacts/ios-simulator-report-export-history.png`
- Files app narrated reopen GIF: `artifacts/ios-simulator-report-export-files-reopen-narrated.gif`

### Safety Notes

- Demo media must stay scoped to `com.jungyeons.iosapphackinglab`.
- Release notes should not include raw simulator containers, private notes, real credentials, or unredacted local paths.
- Run the public-doc sensitive string scan from the README before publishing.
