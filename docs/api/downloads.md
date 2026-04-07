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

=== "JavaScript"

    ```javascript
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
    "downloadUrl": "https://s3.eu-central-1.amazonaws.com/bindist-apps/...",
    "expiresAt": "2025-01-15T12:30:00Z",
    "fileName": "my-app-2.1.0.exe",
    "fileSize": 15728640,
    "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924..."
  }
}
```

### Downloading the File

Use the pre-signed URL to download directly:

=== "curl"

    ```bash
    curl -L -o my-app-2.1.0.exe "DOWNLOAD_URL"
    ```

=== "JavaScript (Node.js)"

    ```javascript
    import { writeFileSync } from 'fs';

    const buffer = await client.downloadFile(downloadUrl);
    writeFileSync('my-app-2.1.0.exe', Buffer.from(buffer));
    ```

=== "PowerShell"

    ```powershell
    Invoke-WebRequest -Uri $downloadUrl -OutFile "my-app-2.1.0.exe"
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

=== "JavaScript"

    ```javascript
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
