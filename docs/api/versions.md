# Versions API

Endpoints for listing versions and version files.

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

## File Types

| Type | Description | Common Extensions |
|------|-------------|-------------------|
| `MAIN` | Primary executable | .exe, .msi, .app, .dmg, .deb, .rpm |
| `DEPENDENCY` | Required libraries | .dll, .so, .dylib, .lib, .jar |
| `CONFIGURATION` | Config files | .json, .xml, .yaml, .yml, .conf, .ini |
| `DOCUMENTATION` | Documentation | .txt, .md, .pdf, .doc, .html |
