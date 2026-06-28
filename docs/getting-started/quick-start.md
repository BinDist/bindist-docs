# Quick Start

Get up and running with BinDist in just a few minutes.

## Prerequisites

- A BinDist account with an API key
- `curl` or any HTTP client

## Step 1: Get Your API Key

After signing up, you'll receive an API key. This key is used to authenticate all API requests.

!!! warning "Keep Your API Key Secure"
    Your API key provides access to your applications. Never share it or commit it to version control.

## Step 2: List Your Applications

Make your first API call to list all applications you have access to:

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      https://api.bindist.eu/v1/applications
    ```

=== "JavaScript"

    ```javascript
    const response = await fetch('https://api.bindist.eu/v1/applications', {
      headers: {
        'Authorization': 'Bearer YOUR_API_KEY'
      }
    });
    const data = await response.json();
    console.log(data);
    ```

=== "PowerShell"

    ```powershell
    $headers = @{
      "Authorization" = "Bearer YOUR_API_KEY"
    }
    Invoke-RestMethod -Uri "https://api.bindist.eu/v1/applications" -Headers $headers
    ```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "applications": [
      {
        "applicationId": "my-app",
        "name": "My Application",
        "description": "A sample application",
        "isActive": true
      }
    ],
    "pagination": {
      "hasMore": false,
      "nextCursor": null
    }
  }
}
```

## Step 3: Get a Download URL

Once you know which application and version you want, request a download URL:

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      "https://api.bindist.eu/v1/downloads/url?applicationId=my-app&version=1.2.0"
    ```

=== "JavaScript"

    ```javascript
    const response = await fetch(
      'https://api.bindist.eu/v1/downloads/url?applicationId=my-app&version=1.2.0',
      {
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY'
        }
      }
    );
    const data = await response.json();
    console.log(data.data.downloadUrl);
    ```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "downloadUrl": "https://storage.bindist.eu/...",
    "expiresAt": "2025-01-15T12:30:00Z",
    "fileName": "my-app-1.2.0.exe",
    "fileSize": 15728640,
    "checksum": "sha256:abc123..."
  }
}
```

## Step 4: Download the File

Use the pre-signed URL to download the file. The URL expires after 30 minutes.

```bash
curl -L -o my-app-1.2.0.exe "DOWNLOAD_URL_FROM_PREVIOUS_STEP"
```

## Next Steps

- [Authentication](authentication.md) - Learn more about API key authentication
- [API Reference](../api/overview.md) - Explore all available endpoints
- [JavaScript SDK](../sdks/javascript.md) - Use our official SDK for easier integration
