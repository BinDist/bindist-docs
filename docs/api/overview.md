# API Overview

The BinDist API is a RESTful API that uses JSON for request and response bodies.

## Base URL

```
https://api.bindist.eu/v1/
```

## Authentication

All endpoints require API key authentication. See [Authentication](../getting-started/authentication.md) for details.

## Response Format

All responses follow this format:

### Success Response

```json
{
  "success": true,
  "data": {
    // Response data here
  }
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

## Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid API key |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `QUOTA_EXCEEDED` | 413 | Storage quota exceeded |
| `INTERNAL_ERROR` | 500 | Server error |

## Pagination

List endpoints support cursor-based pagination:

**Request Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `limit` | number | Maximum items to return (default: 50, max: 100) |
| `cursor` | string | Cursor for next page |

**Response:**

```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "hasMore": true,
      "nextCursor": "eyJsYXN0S2V5Ijp7..."
    }
  }
}
```

To fetch the next page, include the `cursor` parameter:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://api.bindist.eu/v1/applications?cursor=eyJsYXN0S2V5Ijp7..."
```

## Rate Limiting

The API uses rate limiting to ensure fair usage. Current limits:

- **Standard tier**: 100 requests per minute
- **Premium tier**: 500 requests per minute
- **Enterprise tier**: Unlimited

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705312800
```

## Endpoints

### Customer Endpoints

These endpoints are available to all authenticated users:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1/applications` | [List applications](applications.md#list-applications) |
| GET | `/v1/applications/{id}` | [Get application](applications.md#get-application) |
| GET | `/v1/applications/{id}/versions` | [List versions](versions.md#list-versions) |
| GET | `/v1/applications/{id}/versions/{v}/files` | [List version files](versions.md#list-version-files) |
| GET | `/v1/downloads/url` | [Get download URL](downloads.md#get-download-url) |
| POST | `/v1/downloads/share` | [Create share link](downloads.md#create-share-link) |

### Admin Endpoints

These endpoints require an admin API key:

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/management/applications` | [Create application](management.md#create-application) |
| DELETE | `/v1/management/applications/{id}` | [Delete application](management.md#delete-application) |
| POST | `/v1/management/upload` | [Upload binary](management.md#upload-binary) |
| POST | `/v1/management/upload/large-url` | [Get upload URL](management.md#large-file-upload) |
| POST | `/v1/management/upload/large-complete` | [Complete upload](management.md#step-3-complete-upload) |
| GET | `/v1/management/customers` | [List customers](management.md#list-customers) |
| PATCH | `/v1/management/customers/{id}` | [Update customer](management.md#update-customer) |
| POST | `/v1/management/customers/{id}/apikeys` | [Create API key](management.md#create-api-key) |
| GET | `/v1/applications/{id}/stats` | [Get statistics](management.md#get-statistics) |
| GET | `/v1/activity` | [List activity](management.md#list-activity) |
