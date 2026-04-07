# Managing Customers

This guide covers how to create and manage customer accounts and API keys.

## Customer Hierarchy

BinDist uses a two-level customer model:

1. **Admin Accounts** - Full access to manage applications, customers, and settings
2. **Customer Accounts** - Read-only access to download applications

## Listing Customers

View all customers in your account:

```bash
curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  https://api.bindist.eu/v1/management/customers
```

**Response:**

```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "customerId": "cust_abc123",
        "name": "Acme Corporation",
        "tier": "Premium",
        "isActive": true,
        "createdAt": "2024-06-15T10:00:00Z"
      }
    ]
  }
}
```

## Creating API Keys

Create API keys for customers to access your applications:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corporation",
    "tier": "Premium"
  }' \
  https://api.bindist.eu/v1/management/customers/cust_abc123/apikeys
```

**Response:**

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
    The API key is only shown once. Make sure to save it securely and share it with your customer through a secure channel.

## Updating Customers

Update customer information:

```bash
curl -X PATCH \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corp (Updated)",
    "notes": "Enterprise customer since 2024"
  }' \
  https://api.bindist.eu/v1/management/customers/cust_abc123
```

## Deactivating Customers

To revoke a customer's access, set `isActive` to `false`:

```bash
curl -X PATCH \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "isActive": false
  }' \
  https://api.bindist.eu/v1/management/customers/cust_abc123
```

Deactivated customers:

- Cannot authenticate with their API key
- Will receive a `403 Forbidden` error
- Can be reactivated later by setting `isActive: true`

## Regenerating API Keys

If a customer's API key is compromised, regenerate it:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  https://api.bindist.eu/v1/management/customers/cust_abc123/regenerate-key
```

**Response:**

```json
{
  "success": true,
  "data": {
    "customerId": "cust_abc123",
    "apiKey": "cust_abc123.newSecretKeyHere",
    "apiSecret": "newSecretKeyHere",
    "regeneratedAt": "2025-01-15T10:30:00Z"
  }
}
```

!!! note "Key Regeneration"
    The old API key is immediately invalidated. Make sure to communicate the new key to your customer promptly.

## Customer Tiers

Customers can be assigned to different tiers that control access:

| Tier | Description |
|------|-------------|
| `Basic` | Access to basic versions only |
| `Premium` | Access to premium features and versions |
| `Enterprise` | Full access to all versions and features |

### Tier-Based Access Control

When uploading a version, you can specify the required tier:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -F "applicationId=my-app" \
  -F "version=2.0.0-enterprise" \
  -F "requiredTier=Enterprise" \
  -F "file=@./my-app-enterprise.exe" \
  https://api.bindist.eu/v1/management/upload
```

Customers with lower tiers won't see this version in their listings.

## Assigning Applications to Customers

Control which applications each customer can access:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "applicationId": "my-app",
    "name": "My Application",
    "customerIds": ["cust_abc123", "cust_def456"]
  }' \
  https://api.bindist.eu/v1/management/applications
```

## Monitoring Customer Activity

Track customer downloads and usage:

```bash
curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  "https://api.bindist.eu/v1/activity?type=download"
```

**Response:**

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
    ]
  }
}
```

## Best Practices

1. **Use descriptive names** - Include company name and purpose in customer names
2. **Document with notes** - Use the notes field to track customer details
3. **Monitor activity** - Regularly review download activity for unusual patterns
4. **Rotate keys periodically** - Regenerate API keys for security compliance
5. **Tier appropriately** - Assign the minimum tier needed for each customer
