# Uploading Applications

This guide covers how to upload applications and manage versions in BinDist.

## Prerequisites

- An admin API key
- The binary files you want to upload

## Creating an Application

Before uploading files, create an application:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "applicationId": "my-app",
    "name": "My Application",
    "description": "A great application",
    "tags": ["windows", "utility"]
  }' \
  https://api.bindist.eu/v1/management/applications
```

!!! tip "Application ID Format"
    The `applicationId` must be:

    - Lowercase letters, numbers, and hyphens only
    - 3-50 characters long
    - Unique within your account

## Uploading a Version

### Small Files (< 10MB)

For files under 10MB, use the direct upload endpoint:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=1.0.0" \
  -F "releaseNotes=Initial release" \
  -F "file=@./my-app-1.0.0.exe" \
  https://api.bindist.eu/v1/management/upload
```

### Large Files (> 10MB)

For larger files, use the three-step process:

#### Step 1: Get Upload URL

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "applicationId": "my-app",
    "version": "1.0.0",
    "fileName": "my-app-1.0.0.exe",
    "fileSize": 52428800
  }' \
  https://api.bindist.eu/v1/management/upload/large-url
```

#### Step 2: Upload to S3 (or compatible)

```bash
curl -X PUT \
  -H "Content-Type: application/octet-stream" \
  --data-binary @./my-app-1.0.0.exe \
  "UPLOAD_URL_FROM_STEP_1"
```

#### Step 3: Complete Upload

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "uploadId": "UPLOAD_ID_FROM_STEP_1",
    "releaseNotes": "Initial release"
  }' \
  https://api.bindist.eu/v1/management/upload/large-complete
```

## Publishing a Version

!!! warning "Uploaded versions start disabled"
    A new version cannot be downloaded until you enable it. Until then it is left out
    of `GET /v1/applications/{id}/versions`, and `GET /v1/downloads/url` returns
    `403 Forbidden` for it. This is intentional: you can test the upload before your
    customers get it.

**Test before publishing:** send `X-Channel: Test` to list and download disabled versions:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  -H "X-Channel: Test" \
  "https://api.bindist.eu/v1/downloads/url?applicationId=my-app&version=1.0.0"
```

**Publish:** enable the version with an admin key. For multi-file versions, do this once
after all files are uploaded.

```bash
curl -X PATCH \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"isEnabled": true}' \
  https://api.bindist.eu/v1/applications/my-app/versions/1.0.0
```

If two-factor authentication (TOTP) is enabled on your account, include the current
code: `{"isEnabled": true, "totpCode": "123456"}`.

Send `{"isEnabled": false}` to withdraw a version again. The same endpoint can also
update `releaseNotes`. See the [Update Version](../api/versions.md#update-version) reference.

## Multi-File Versions

You can upload multiple files for a single version (e.g., main executable + dependencies).

Upload each file separately with the same version:

```bash
# Upload main executable
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=1.0.0" \
  -F "fileType=MAIN" \
  -F "file=@./my-app.exe" \
  https://api.bindist.eu/v1/management/upload

# Upload dependency
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=1.0.0" \
  -F "fileType=DEPENDENCY" \
  -F "file=@./runtime.dll" \
  https://api.bindist.eu/v1/management/upload

# Upload documentation
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=1.0.0" \
  -F "fileType=DOCUMENTATION" \
  -F "file=@./README.pdf" \
  https://api.bindist.eu/v1/management/upload
```

### File Types

| Type | Description | Auto-Detected Extensions |
|------|-------------|-------------------------|
| `MAIN` | Primary executable | .exe, .msi, .app, .dmg, .deb, .rpm |
| `DEPENDENCY` | Required libraries | .dll, .so, .dylib, .lib, .jar |
| `CONFIGURATION` | Config files | .json, .xml, .yaml, .yml, .conf, .ini |
| `DOCUMENTATION` | Documentation | .txt, .md, .pdf, .doc, .html |

!!! note "Auto-Detection"
    If you don't specify `fileType`, it's automatically detected from the file extension.

## Version Naming

BinDist supports any version string format:

- Semantic versioning: `1.0.0`, `2.1.0-beta`, `3.0.0-rc.1`
- Date-based: `2025.01.15`, `2025-01-15`
- Build numbers: `build-1234`, `v1234`

!!! tip "Best Practice"
    Use semantic versioning (`major.minor.patch`) for clarity and consistency.

## Storage Quota

Your account has a storage quota. Check your usage:

```bash
curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  "https://api.bindist.eu/v1/control/tenants/YOUR_TENANT_ID"
```

If you exceed the quota, uploads will fail with a `QUOTA_EXCEEDED` error.

## CI/CD Integration

### GitHub Actions

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: make build

      - name: Upload to BinDist
        env:
          BINDIST_API_KEY: ${{ secrets.BINDIST_API_KEY }}
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          curl -X POST \
            -H "Authorization: Bearer $BINDIST_API_KEY" \
            -F "applicationId=my-app" \
            -F "version=$VERSION" \
            -F "releaseNotes=Release $VERSION" \
            -F "file=@./dist/my-app" \
            https://api.bindist.eu/v1/management/upload

          # Publish it (uploaded versions start disabled). Omit this step to
          # release through the Test channel first and enable it later.
          curl -X PATCH \
            -H "Authorization: Bearer $BINDIST_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"isEnabled": true}' \
            "https://api.bindist.eu/v1/applications/my-app/versions/$VERSION"
```

### PowerShell Script

```powershell
.\scripts\ci-scripts\Upload-Binary.ps1 `
  -ApplicationId "my-app" `
  -Version "1.0.0" `
  -FilePath ".\build\my-app.exe" `
  -ReleaseNotes "Initial release"
```
