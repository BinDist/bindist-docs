# Versions API

Endpoints for listing versions and version files, and for publishing a version.

## List Versions

List all versions for a specific application.

```
GET /v1/applications/{applicationId}/versions
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |

### Headers

| Header | Description |
|--------|-------------|
| `X-Channel` | Optional. Access channel for disabled versions |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      https://api.bindist.eu/v1/applications/my-app/versions
    ```

=== "Go"

    ```go
    versions, err := client.ListVersions(ctx, "my-app")

    // Include disabled / pre-release versions:
    versions, err = client.ListVersions(ctx, "my-app",
        bindist.WithChannel(bindist.ChannelTest))
    ```

=== "Rust"

    ```rust
    use bindist::{Channel, ListVersionsOptions};

    let versions = client
        .list_versions("my-app", &ListVersionsOptions::default())
        .await?;

    // Include disabled / pre-release versions:
    let versions = client
        .list_versions(
            "my-app",
            &ListVersionsOptions {
                channel: Some(Channel::Test),
                ..Default::default()
            },
        )
        .await?;
    ```

=== "JavaScript"

    ```typescript
    const result = await client.listVersions('my-app');
    console.log(result.data.versions);
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "versions": [
      {
        "applicationId": "my-app",
        "version": "2.1.0",
        "versionId": "v-abc123",
        "isActive": true,
        "releaseNotes": "Bug fixes and performance improvements",
        "fileSize": 15728640,
        "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "downloadCount": 450,
        "createdAt": "2025-01-10T10:00:00Z"
      },
      {
        "applicationId": "my-app",
        "version": "2.0.0",
        "versionId": "v-def456",
        "isActive": true,
        "releaseNotes": "Major release with new features",
        "fileSize": 14680064,
        "checksum": "sha256:abc123...",
        "downloadCount": 823,
        "createdAt": "2024-11-15T14:30:00Z"
      }
    ]
  }
}
```

---

## List Version Files

List all files for a specific version. Used for multi-file applications.

```
GET /v1/applications/{applicationId}/versions/{version}/files
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |
| `version` | string | The version string |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      https://api.bindist.eu/v1/applications/my-app/versions/2.1.0/files
    ```

=== "Go"

    ```go
    files, err := client.ListVersionFiles(ctx, "my-app", "2.1.0")
    ```

=== "Rust"

    ```rust
    let files = client.list_version_files("my-app", "2.1.0").await?;
    ```

=== "JavaScript"

    ```typescript
    const result = await client.listVersionFiles('my-app', '2.1.0');
    console.log(result.data.files);
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "files": [
      {
        "fileId": "f-main001",
        "fileName": "my-app-2.1.0.exe",
        "fileType": "MAIN",
        "fileSize": 15728640,
        "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924...",
        "order": 1
      },
      {
        "fileId": "f-dep001",
        "fileName": "runtime-library.dll",
        "fileType": "DEPENDENCY",
        "fileSize": 2097152,
        "checksum": "sha256:abc123...",
        "order": 2
      },
      {
        "fileId": "f-doc001",
        "fileName": "README.md",
        "fileType": "DOCUMENTATION",
        "fileSize": 4096,
        "checksum": "sha256:def456...",
        "order": 3
      }
    ]
  }
}
```

---

## Update Version

Publish or withdraw a version, or change its release notes. **Requires an admin API key.**

```
PATCH /v1/applications/{applicationId}/versions/{version}
```

Every uploaded version starts **disabled** (`isEnabled: false`). A disabled version is
left out of [List Versions](#list-versions), and
[Get Download URL](downloads.md#get-download-url) returns `403 Forbidden` for it, unless
the request sends `X-Channel: Test`. Set `isEnabled: true` to publish it to your customers.

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |
| `version` | string | The version string |

### Request Body

At least one of `isEnabled` or `releaseNotes` is required.

| Field | Type | Description |
|-------|------|-------------|
| `isEnabled` | boolean | `true` publishes the version; `false` withdraws it again |
| `releaseNotes` | string \| null | New release notes (max 5000 characters). `""` or `null` clears them |
| `totpCode` | string | 6-digit code. Required when setting `isEnabled: true` on an account with two-factor authentication (TOTP) enabled |

Unknown fields are ignored. In particular `isActive` cannot be changed here.

### Example Request

=== "curl"

    ```bash
    curl -X PATCH \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{"isEnabled": true}' \
      https://api.bindist.eu/v1/applications/my-app/versions/2.1.0
    ```

=== "Go"

    ```go
    enabled := true
    _, err := admin.UpdateVersion(ctx, "my-app", "2.1.0",
        bindist.UpdateVersionOptions{IsEnabled: &enabled})
    ```

=== "JavaScript"

    ```typescript
    await client.updateVersion('my-app', '2.1.0', { isEnabled: true });
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "message": "Version updated successfully",
    "applicationId": "my-app",
    "version": "2.1.0",
    "releaseNotes": "Bug fixes and performance improvements",
    "isActive": true,
    "isEnabled": true,
    "updatedAt": "2025-01-10T10:05:00Z"
  }
}
```

Enabling or disabling a version is recorded in the audit log as `VERSION_PROMOTED` /
`VERSION_DEMOTED`.

### Errors

| Status | Cause |
|--------|-------|
| `400` | No update fields provided, invalid body, or `totpCode` missing while TOTP is enabled |
| `401` | Invalid `totpCode` |
| `403` | The API key is not an admin key |
| `404` | Application or version not found |

## File Types

| Type | Description | Common Extensions |
|------|-------------|-------------------|
| `MAIN` | Primary executable | .exe, .msi, .app, .dmg, .deb, .rpm |
| `DEPENDENCY` | Required libraries | .dll, .so, .dylib, .lib, .jar |
| `CONFIGURATION` | Config files | .json, .xml, .yaml, .yml, .conf, .ini |
| `DOCUMENTATION` | Documentation | .txt, .md, .pdf, .doc, .html |
