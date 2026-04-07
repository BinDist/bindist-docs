# JavaScript SDK

The official JavaScript/TypeScript client for the BinDist API.

## Installation

```bash
npm install @bindist/client
```

Or with yarn:

```bash
yarn add @bindist/client
```

## Quick Start

```typescript
import { createBinDistClient } from '@bindist/client';

const client = createBinDistClient({
  baseUrl: 'https://api.bindist.eu',
  apiKey: process.env.BINDIST_API_KEY!
});

// List applications
const apps = await client.listApplications();
if (apps.success) {
  console.log(apps.data.applications);
}

// Get download URL
const download = await client.getDownloadInfo('my-app', '2.1.0');
if (download.success) {
  console.log(download.data.downloadUrl);
}
```

## Configuration

```typescript
interface BinDistClientConfig {
  baseUrl: string;    // API base URL
  apiKey: string;     // Your API key
  timeout?: number;   // Request timeout in ms (default: 30000)
}
```

## Methods

### Applications

#### listApplications

List all accessible applications.

```typescript
const result = await client.listApplications({
  search: 'my-app',
  tag: 'windows',
  limit: 10
});
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `search` | string | Search by name or description |
| `tag` | string | Filter by tag |
| `limit` | number | Maximum items |
| `cursor` | string | Pagination cursor |

#### getApplication

Get details for a specific application.

```typescript
const result = await client.getApplication('my-app');
```

#### deleteApplication

Soft delete an application (admin only).

```typescript
const result = await client.deleteApplication('my-app');
```

### Versions

#### listVersions

List all versions for an application.

```typescript
const result = await client.listVersions('my-app');
```

#### listVersionFiles

List all files in a version.

```typescript
const result = await client.listVersionFiles('my-app', '2.1.0');
```

### Downloads

#### getDownloadInfo

Get a pre-signed download URL.

```typescript
const result = await client.getDownloadInfo('my-app', '2.1.0');
if (result.success) {
  const { downloadUrl, fileName, fileSize } = result.data;
  console.log(`Download ${fileName} (${fileSize} bytes)`);
  console.log(downloadUrl);
}
```

#### downloadFile

Download a file and return as ArrayBuffer.

```typescript
const info = await client.getDownloadInfo('my-app', '2.1.0');
if (info.success) {
  const buffer = await client.downloadFile(info.data.downloadUrl);
  // Save to file
  import { writeFileSync } from 'fs';
  writeFileSync('output.exe', Buffer.from(buffer));
}
```

#### downloadFileStream

Download a file as a stream (for large files).

```typescript
const stream = await client.downloadFileStream(downloadUrl);
// Pipe to file or process
```

#### createShareLink

Create a shareable download link.

```typescript
const result = await client.createShareLink({
  applicationId: 'my-app',
  version: '2.1.0',
  expiresInMinutes: 60
});
```

### Customers (Admin)

#### listCustomers

List all customers.

```typescript
const result = await client.listCustomers();
```

#### updateCustomer

Update a customer.

```typescript
const result = await client.updateCustomer('cust_123', {
  name: 'New Name',
  isActive: true
});
```

#### regenerateCustomerKey

Regenerate a customer's API key.

```typescript
const result = await client.regenerateCustomerKey('cust_123');
if (result.success) {
  console.log('New API key:', result.data.apiKey);
}
```

### Backups (Admin)

#### listBackups

List available backups.

```typescript
const result = await client.listBackups();
```

#### startBackup

Start a new backup.

```typescript
const result = await client.startBackup('MANUAL');
```

#### getBackupContents

Get backup contents with download URLs.

```typescript
const result = await client.getBackupContents('backup_123', true);
```

### Account (Admin)

#### getAccount

Get account information.

```typescript
const result = await client.getAccount({
  includeResources: true,
  includeEvents: true
});
```

#### archiveTenant

Archive/cancel the account.

```typescript
const result = await client.archiveTenant();
```

### Activity (Admin)

#### listActivity

List recent activity (uploads/downloads).

```typescript
const result = await client.listActivity({
  type: 'download',
  applicationId: 'my-app',
  limit: 50
});
```

## Error Handling

All methods return an `ApiResponse` object:

```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}
```

Example error handling:

```typescript
const result = await client.getApplication('unknown-app');

if (!result.success) {
  console.error(`Error ${result.error?.code}: ${result.error?.message}`);
  // Handle specific errors
  if (result.error?.code === 'NOT_FOUND') {
    console.log('Application does not exist');
  }
}
```

## TypeScript Support

The SDK is written in TypeScript and includes full type definitions. All response types are exported:

```typescript
import {
  ApplicationInfo,
  VersionInfo,
  DownloadInfo,
  CustomerInfo,
  // ... more types
} from '@bindist/client';
```
