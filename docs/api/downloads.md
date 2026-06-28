# Downloads API

Endpoints for generating download URLs and share links.

## Get Download URL

Generate a pre-signed URL to download a file.

```
GET /v1/downloads/url
```

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `applicationId` | string | Yes | The application ID |
| `version` | string | Yes | The version string |
| `fileId` | string | No | Specific file ID (for multi-file versions) |

!!! note "URL Expiration"
    Download URLs expire after **30 minutes**. Generate a new URL if the download doesn't complete in time.

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      "https://api.bindist.eu/v1/downloads/url?applicationId=my-app&version=2.1.0"
    ```

=== "Go"

    ```go
    download, err := client.GetDownloadInfo(ctx, "my-app", "2.1.0", "")
    if download.Success {
        fmt.Println(download.Data.URL)
    }
    ```

    The fourth argument is an optional `fileID` for multi-file versions; pass `""` for the default `MAIN` file.

=== "Rust"

    ```rust
    use bindist::GetDownloadInfoOptions;

    let info = client
        .get_download_info(
            "my-app",
            "2.1.0",
            &GetDownloadInfoOptions::default(),
        )
        .await?;
    println!("{}", info.url);
    ```

=== "JavaScript"

    ```typescript
    const result = await client.getDownloadInfo('my-app', '2.1.0');
    if (result.success) {
      console.log(result.data.downloadUrl);
    }
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "downloadUrl": "https://storage.bindist.eu/bindist-apps/...",
    "expiresAt": "2025-01-15T12:30:00Z",
    "fileName": "my-app-2.1.0.exe",
    "fileSize": 15728640,
    "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924..."
  }
}
```

### Downloading the File

The SDKs wrap "get URL → GET pre-signed URL → write bytes" into a single call. With curl, do it in two steps:

=== "curl"

    ```bash
    curl -L -o my-app-2.1.0.exe "DOWNLOAD_URL"
    ```

=== "Go"

    ```go
    // Into memory, with optional SHA256 checksum verification
    content, metadata, err := client.DownloadFile(ctx, "my-app", "2.1.0", "", true)
    os.WriteFile(metadata.FileName, content, 0644)

    // Stream straight to disk (good for large files)
    f, _ := os.Create("my-app-2.1.0.exe")
    defer f.Close()
    metadata, err = client.DownloadFileToWriter(ctx, "my-app", "2.1.0", "", f)
    ```

=== "Rust"

    ```rust
    use bindist::GetDownloadInfoOptions;

    let (info, bytes) = client
        .download("my-app", "2.1.0", &GetDownloadInfoOptions::default())
        .await?;
    std::fs::write(&info.file_name, &bytes)?;
    ```

=== "JavaScript"

    ```typescript
    import { writeFileSync } from 'fs';

    const info = await client.getDownloadInfo('my-app', '2.1.0');
    const buffer = await client.downloadFile(info.data.downloadUrl);
    writeFileSync('my-app-2.1.0.exe', Buffer.from(buffer));

    // For large files, prefer the streaming variant:
    const stream = await client.downloadFileStream(info.data.downloadUrl);
    ```

### Error Responses

**Version Not Found (404)**

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Version not found"
  }
}
```

**Tier Access Denied (403)**

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "This version requires Premium tier access"
  }
}
```

---

## Create Share Link

Create a shareable download link that can be used without authentication.

```
POST /v1/downloads/share
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `applicationId` | string | Yes | The application ID |
| `version` | string | Yes | The version string |
| `fileId` | string | No | Specific file ID |
| `expiresInMinutes` | number | No | Expiration time (default: 30, max: 1440) |

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "applicationId": "my-app",
        "version": "2.1.0",
        "expiresInMinutes": 60
      }' \
      https://api.bindist.eu/v1/downloads/share
    ```

=== "Go"

    ```go
    share, err := client.CreateShareLink(ctx, "my-app", "2.1.0", "", 60)
    if share.Success {
        fmt.Println(share.Data.ShareURL)
    }
    ```

=== "Rust"

    ```rust
    use bindist::CreateShareLinkRequest;

    let share = client
        .create_share_link(&CreateShareLinkRequest {
            application_id: "my-app".into(),
            version: "2.1.0".into(),
            file_id: None,
            expires_in_minutes: Some(60),
        })
        .await?;
    println!("{}", share.share_url);
    ```

=== "JavaScript"

    ```typescript
    const result = await client.createShareLink({
      applicationId: 'my-app',
      version: '2.1.0',
      expiresInMinutes: 60
    });
    console.log(result.data.shareUrl);
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "shareUrl": "https://api.bindist.eu/v1/downloads/share/tok_abc123xyz",
    "expiresAt": "2025-01-15T13:00:00Z",
    "token": "tok_abc123xyz"
  }
}
```

!!! tip "Use Cases for Share Links"
    - Send download links to users without API keys
    - Embed in emails or documentation
    - Time-limited access for testing or demos
