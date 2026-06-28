# Management API

Admin endpoints for managing applications, customers, and uploads.

!!! warning "Admin Access Required"
    All endpoints on this page require an **admin API key**.

!!! info "SDK coverage"
    Go examples use the [`AdminClient`](../sdks/go.md#admin-client) (`bindist.NewAdminClient`). The Rust SDK is customer-only and does not expose admin endpoints — call them over HTTP directly, or use the Go SDK.

---

## Create Application

Create a new application.

```
POST /v1/management/applications
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `applicationId` | string | Yes | Unique identifier (lowercase, alphanumeric, hyphens) |
| `name` | string | Yes | Display name |
| `description` | string | No | Application description |
| `tags` | string[] | No | Tags for filtering |
| `customerIds` | string[] | No | Customer IDs with access |

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "applicationId": "my-new-app",
        "name": "My New Application",
        "description": "A brand new application",
        "tags": ["windows", "utility"]
      }' \
      https://api.bindist.eu/v1/management/applications
    ```

=== "Go"

    ```go
    admin := bindist.NewAdminClient("https://api.bindist.eu", "YOUR_ADMIN_API_KEY")

    app, err := admin.CreateApplication(ctx, bindist.CreateApplicationOptions{
        ApplicationID: "my-new-app",
        Name:          "My New Application",
        Description:   "A brand new application",
        Tags:          []string{"windows", "utility"},
    })
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "applicationId": "my-new-app",
    "name": "My New Application",
    "description": "A brand new application",
    "tags": ["windows", "utility"],
    "isActive": true,
    "createdAt": "2025-01-15T10:00:00Z"
  }
}
```

---

## Delete Application

Soft delete an application. The application and its data remain but are hidden from listings.

```
DELETE /v1/management/applications/{applicationId}
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |

### Example Request

=== "curl"

    ```bash
    curl -X DELETE \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      https://api.bindist.eu/v1/management/applications/my-app
    ```

=== "Go"

    ```go
    _, err := admin.DeleteApplication(ctx, "my-app")
    ```

=== "JavaScript"

    ```typescript
    const result = await client.deleteApplication('my-app');
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "message": "Application deleted successfully",
    "applicationId": "my-app",
    "deletedAt": "2025-01-15T10:30:00Z"
  }
}
```

---

## Upload Binary

Upload a binary file for a version. For files larger than 10MB, use the large file upload endpoints.

```
POST /v1/management/upload
```

### Request Body (multipart/form-data)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `applicationId` | string | Yes | The application ID |
| `version` | string | Yes | Version string |
| `file` | file | Yes | The binary file |
| `releaseNotes` | string | No | Release notes |
| `fileType` | string | No | File type (MAIN, DEPENDENCY, etc.) |

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -F "applicationId=my-app" \
      -F "version=2.2.0" \
      -F "releaseNotes=New features and bug fixes" \
      -F "file=@./my-app-2.2.0.exe" \
      https://api.bindist.eu/v1/management/upload
    ```

=== "Go"

    ```go
    content, _ := os.ReadFile("./my-app-2.2.0.exe")
    result, err := admin.UploadSmallFile(ctx,
        "my-app", "2.2.0", "my-app-2.2.0.exe", content,
        "New features and bug fixes")
    ```

    For files ≥ 10 MB, use `admin.UploadLargeFile(...)` — it transparently runs the three-step pre-signed flow described below.

---

## Large File Upload

For files larger than 10MB, use the three-step upload process.

!!! tip "Go shortcut"
    The Go SDK's `admin.UploadLargeFile(ctx, appID, version, fileName, content, releaseNotes)` wraps all three steps below (get URL → PUT to S3 (or compatible) → complete). Reach for the raw steps only when you need finer control (resumable uploads, custom retry, alternative runtimes).

### Step 1: Get Upload URL

```
POST /v1/management/upload/large-url
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `applicationId` | string | Yes | The application ID |
| `version` | string | Yes | Version string |
| `fileName` | string | Yes | Original filename |
| `fileSize` | number | Yes | File size in bytes |
| `contentType` | string | No | MIME type |

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "applicationId": "my-app",
        "version": "2.2.0",
        "fileName": "my-app-2.2.0.exe",
        "fileSize": 52428800
      }' \
      https://api.bindist.eu/v1/management/upload/large-url
    ```

=== "Go"

    ```go
    resp, err := admin.GetLargeUploadURL(ctx,
        "my-app", "2.2.0", "my-app-2.2.0.exe",
        52428800, "application/octet-stream")
    uploadURL := resp.Data.UploadURL
    uploadID  := resp.Data.UploadID
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "uploadUrl": "https://storage.bindist.eu/...",
    "uploadId": "upl_abc123",
    "expiresAt": "2025-01-15T11:00:00Z"
  }
}
```

### Step 2: Upload to S3 (or compatible)

Upload the file directly to the pre-signed URL:

```bash
curl -X PUT \
  -H "Content-Type: application/octet-stream" \
  --data-binary @./my-app-2.2.0.exe \
  "UPLOAD_URL_FROM_STEP_1"
```

### Step 3: Complete Upload

```
POST /v1/management/upload/large-complete
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `uploadId` | string | Yes | Upload ID from step 1 |
| `applicationId` | string | Yes | The application ID |
| `version` | string | Yes | Version string |
| `fileName` | string | Yes | Original filename |
| `fileSize` | number | Yes | File size in bytes |
| `checksum` | string | No | SHA256 checksum of the upload |
| `releaseNotes` | string | No | Release notes |

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "uploadId": "upl_abc123",
        "applicationId": "my-app",
        "version": "2.2.0",
        "fileName": "my-app-2.2.0.exe",
        "fileSize": 52428800,
        "releaseNotes": "Major release"
      }' \
      https://api.bindist.eu/v1/management/upload/large-complete
    ```

=== "Go"

    ```go
    result, err := admin.CompleteLargeUpload(ctx,
        "upl_abc123", "my-app", "2.2.0",
        "my-app-2.2.0.exe", 52428800,
        "", "Major release")
    ```

---

## List Customers

List all customers in your account.

```
GET /v1/management/customers
```

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      "https://api.bindist.eu/v1/management/customers?page=1&pageSize=20"
    ```

=== "Go"

    ```go
    customers, err := admin.ListCustomers(ctx, 1, 20)
    ```

=== "JavaScript"

    ```typescript
    const result = await client.listCustomers();
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "customerId": "cust_abc123",
        "name": "Acme Corp",
        "tier": "Premium",
        "isActive": true,
        "createdAt": "2024-06-15T10:00:00Z"
      }
    ]
  }
}
```

---

## Update Customer

Update a customer's information.

```
PATCH /v1/management/customers/{customerId}
```

### Request Body

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Customer name |
| `isActive` | boolean | Active status |
| `notes` | string | Admin notes |

### Example Request

=== "curl"

    ```bash
    curl -X PATCH \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{ "name": "Acme Corp (renamed)", "isActive": true }' \
      https://api.bindist.eu/v1/management/customers/cust_abc123
    ```

=== "Go"

    ```go
    name := "Acme Corp (renamed)"
    active := true
    _, err := admin.UpdateCustomer(ctx, "cust_abc123", &name, &active, nil)
    ```

    Pointer fields let you distinguish "leave unchanged" (`nil`) from "set to zero value".

=== "JavaScript"

    ```typescript
    const result = await client.updateCustomer('cust_abc123', {
      name: 'Acme Corp (renamed)',
      isActive: true,
    });
    ```

---

## Create API Key

Create a new API key for a customer.

```
POST /v1/management/customers/{customerId}/apikeys
```

### Example Request

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      https://api.bindist.eu/v1/management/customers/cust_abc123/apikeys
    ```

=== "JavaScript"

    ```typescript
    const result = await client.regenerateCustomerKey('cust_abc123');
    if (result.success) {
      console.log('New API key:', result.data.apiKey);
    }
    ```

!!! note "Go SDK"
    The Go SDK doesn't ship a dedicated method for this endpoint. Use `admin.CreateCustomer(...)` if you're provisioning a brand-new customer (it returns the initial key), or call this endpoint over HTTP for additional keys on an existing customer.

### Example Response

```json
{
  "success": true,
  "data": {
    "customerId": "cust_abc123",
    "apiKey": "cust_abc123.xYz789SecretKeyHere",
    "createdAt": "2025-01-15T10:00:00Z"
  }
}
```

!!! warning "Save the API Key"
    The API key is only shown once. Store it securely.

---

## Get Statistics

Get download statistics for an application.

```
GET /v1/applications/{applicationId}/stats
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `applicationId` | string | The application ID |

### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `version` | string | Filter by specific version |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      https://api.bindist.eu/v1/applications/my-app/stats
    ```

=== "Go"

    ```go
    stats, err := client.GetStats(ctx, "my-app")
    ```

    The Go SDK exposes `GetStats` on the customer `Client` type, but the endpoint requires an admin key — pass your admin key to `bindist.NewClient(...)` for this call.

!!! note "Rust and JavaScript SDKs"
    The statistics endpoint isn't covered by the Rust or JavaScript SDK clients yet. Call it directly via HTTP, or use the Go SDK.

### Example Response

```json
{
  "success": true,
  "data": {
    "applicationId": "my-app",
    "totalDownloads": 1523,
    "downloadsByVersion": {
      "2.1.0": 450,
      "2.0.0": 823,
      "1.5.0": 250
    },
    "downloadsByDay": [
      { "date": "2025-01-10", "count": 45 },
      { "date": "2025-01-09", "count": 52 },
      { "date": "2025-01-08", "count": 38 }
    ]
  }
}
```

---

## List Activity

List recent upload and download activity.

```
GET /v1/activity
```

### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | string | Filter by `upload` or `download` |
| `applicationId` | string | Filter by application |
| `limit` | number | Maximum items |
| `cursor` | string | Pagination cursor |

### Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      "https://api.bindist.eu/v1/activity?type=download&limit=20"
    ```

=== "Go"

    ```go
    activity, err := admin.ListActivity(ctx, "download", "", 1, 20)
    ```

=== "JavaScript"

    ```typescript
    const result = await client.listActivity({
      type: 'download',
      limit: 20,
    });
    ```

### Example Response

```json
{
  "success": true,
  "data": {
    "activities": [
      {
        "type": "download",
        "applicationId": "my-app",
        "version": "2.1.0",
        "customerId": "cust_abc123",
        "clientIp": "192.168.1.100",
        "userAgent": "curl/7.68.0",
        "timestamp": "2025-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "hasMore": true,
      "nextCursor": "..."
    }
  }
}
```
