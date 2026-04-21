# Applications API

Endpoints for listing and retrieving application information.

## List Applications

List all applications accessible to the authenticated user.

```
GET /v1/applications
```

### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Search by name or description |
| `tag` | string | Filter by tag |
| `limit` | number | Maximum items (default: 50, max: 100) |
| `cursor` | string | Pagination cursor |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      "https://api.bindist.eu/v1/applications?limit=10"
    ```

=== "Go"

    ```go
    import bindist "github.com/BinDist/bindist-api-go"

    client := bindist.NewClient("https://api.bindist.eu", "YOUR_API_KEY")
    apps, err := client.ListApplications(ctx, &bindist.ListApplicationsOptions{
        PageSize: 10,
    })
    ```

=== "Rust"

    ```rust
    use bindist::{Client, ListApplicationsOptions};

    let client = Client::new("https://api.bindist.eu", "YOUR_API_KEY")?;
    let page = client
        .list_applications(&ListApplicationsOptions {
            limit: Some(10),
            ..Default::default()
        })
        .await?;
    ```

=== "JavaScript"

    ```typescript
    import { createBinDistClient } from '@bindist/client';

    const client = createBinDistClient({
      baseUrl: 'https://api.bindist.eu',
      apiKey: 'YOUR_API_KEY'
    });

    const result = await client.listApplications({ limit: 10 });
    console.log(result.data.applications);
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "applications": [
      {
        "applicationId": "my-app",
        "name": "My Application",
        "description": "A sample application for demonstration",
        "isActive": true,
        "tags": ["windows", "utility"],
        "createdAt": "2024-06-15T10:30:00Z",
        "updatedAt": "2025-01-10T14:22:00Z"
      }
    ],
    "pagination": {
      "hasMore": false,
      "nextCursor": null
    }
  }
}
```

---

## Get Application

Get details for a specific application.

```
GET /v1/applications/{applicationId}
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_API_KEY" \
      https://api.bindist.eu/v1/applications/my-app
    ```

=== "Go"

    ```go
    app, err := client.GetApplication(ctx, "my-app")
    ```

=== "Rust"

    ```rust
    let app = client.get_application("my-app").await?;
    ```

=== "JavaScript"

    ```typescript
    const result = await client.getApplication('my-app');
    console.log(result.data);
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "applicationId": "my-app",
    "name": "My Application",
    "description": "A sample application for demonstration",
    "isActive": true,
    "tags": ["windows", "utility"],
    "createdAt": "2024-06-15T10:30:00Z",
    "updatedAt": "2025-01-10T14:22:00Z",
    "versionCount": 5
  }
}
```

### Error Responses

**Application Not Found (404)**

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Application not found"
  }
}
```
