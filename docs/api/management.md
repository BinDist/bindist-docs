# Management API

Admin endpoints for managing applications, customers, and uploads.

!!! warning "Admin Access Required"
    All endpoints on this page require an **admin API key**.

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

```bash
curl -X DELETE \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  https://api.bindist.eu/v1/management/applications/my-app
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

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=2.2.0" \
  -F "releaseNotes=New features and bug fixes" \
  -F "file=@./my-app-2.2.0.exe" \
  https://api.bindist.eu/v1/management/upload
```

---

## Large File Upload

For files larger than 10MB, use the two-step upload process.

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

### Example Response

```json
{
  "success": true,
  "data": {
    "uploadUrl": "https://s3.eu-central-1.amazonaws.com/...",
    "uploadId": "upl_abc123",
    "expiresAt": "2025-01-15T11:00:00Z"
  }
}
```

### Step 2: Upload to S3

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
| `releaseNotes` | string | No | Release notes |

---

## List Customers

List all customers in your account.

```
GET /v1/management/customers
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

---

## Create API Key

Create a new API key for a customer.

```
POST /v1/management/customers/{customerId}/apikeys
```

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
