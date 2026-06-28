# Backups

BinDist provides automated and manual backup capabilities to protect your data.

## Backup Types

| Type | Description | Frequency |
|------|-------------|-----------|
| `AUTOMATIC` | System-generated backups | Daily |
| `MANUAL` | User-triggered backups | On-demand |

## What's Included in Backups

Backups include:

- **Metadata** - Application definitions, versions, customers
- **Binary files** - All uploaded application files
- **Configuration** - Account settings and permissions

## Listing Backups

View available backups:

```bash
curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  https://api.bindist.eu/v1/control/tenants/YOUR_TENANT_ID/backups
```

**Response:**

```json
{
  "success": true,
  "data": {
    "backups": [
      {
        "backupId": "bak_20250115_auto",
        "backupType": "AUTOMATIC",
        "status": "COMPLETED",
        "sizeBytes": 1073741824,
        "createdAt": "2025-01-15T03:00:00Z",
        "expiresAt": "2025-04-15T03:00:00Z"
      },
      {
        "backupId": "bak_20250114_manual",
        "backupType": "MANUAL",
        "status": "COMPLETED",
        "sizeBytes": 1073741824,
        "createdAt": "2025-01-14T10:30:00Z",
        "expiresAt": "2025-04-14T10:30:00Z"
      }
    ]
  }
}
```

## Starting a Manual Backup

Trigger a backup immediately:

=== "curl"

    ```bash
    curl -X POST \
      -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{"backupType": "MANUAL"}' \
      https://api.bindist.eu/v1/control/tenants/YOUR_TENANT_ID/backups
    ```

=== "JavaScript"

    ```javascript
    const result = await client.startBackup('MANUAL');
    if (result.success) {
      console.log('Backup started:', result.data.backupId);
    }
    ```

**Response:**

```json
{
  "success": true,
  "data": {
    "backupId": "bak_20250115_manual",
    "status": "IN_PROGRESS",
    "createdAt": "2025-01-15T10:30:00Z"
  }
}
```

!!! note "Backup Duration"
    Backup time depends on the amount of data. Large accounts may take several minutes.

## Getting Backup Contents

View the contents of a backup with download URLs:

```bash
curl -H "Authorization: Bearer YOUR_ADMIN_API_KEY" \
  "https://api.bindist.eu/v1/control/tenants/YOUR_TENANT_ID/backups/bak_20250115_auto?generateUrls=true"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "backupId": "bak_20250115_auto",
    "status": "COMPLETED",
    "contents": {
      "metadata": {
        "downloadUrl": "https://storage.bindist.eu/...",
        "sizeBytes": 1048576
      },
      "files": [
        {
          "applicationId": "my-app",
          "version": "2.1.0",
          "fileName": "my-app-2.1.0.exe",
          "downloadUrl": "https://storage.bindist.eu/...",
          "sizeBytes": 15728640
        }
      ]
    }
  }
}
```

## Downloading Backup Files

Use the pre-signed URLs to download backup files:

```bash
# Download metadata
curl -o metadata.json "METADATA_DOWNLOAD_URL"

# Download application file
curl -o my-app-2.1.0.exe "FILE_DOWNLOAD_URL"
```

!!! warning "URL Expiration"
    Download URLs expire after 1 hour. Request new URLs if needed.

## Backup Lifecycle

### Retention

- **Standard tier**: 30-day retention
- **Premium tier**: 90-day retention
- **Enterprise tier**: 365-day retention

### Archival Transition

Older backups are automatically moved to lower-cost archival storage for cost optimization:

| Age | Storage Class |
|-----|---------------|
| 0-30 days | Standard storage |
| 30-90 days | Infrequent-access storage |
| 90+ days | Cold archive |

!!! note "Retrieval Time"
    Cold archive restores may take 12-48 hours.

## Restore Process

To restore from a backup, contact support with:

1. Your tenant ID
2. The backup ID to restore from
3. Whether you want a full restore or specific items

!!! info "Self-Service Restore"
    Self-service restore is coming soon. For now, contact support@bindist.eu.

## Best Practices

1. **Schedule manual backups** before major changes
2. **Verify backup contents** periodically
3. **Download critical backups** to local storage
4. **Test restore procedures** in a staging environment
5. **Monitor backup status** for any failures

## Backup Notifications

Set up notifications for backup events:

1. Go to Account Settings
2. Enable "Backup Notifications"
3. Configure email recipients

You'll receive notifications for:

- Backup completion
- Backup failures
- Low storage warnings
