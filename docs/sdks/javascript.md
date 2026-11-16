# JavaScript SDK

The official JavaScript/TypeScript client for the BinDist API, published on npm as
[`@bindist/client`](https://www.npmjs.com/package/@bindist/client). It ships both ESM and
CommonJS builds with type definitions, and needs Node.js 18 or later (or any runtime with a
global `fetch`).

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
  console.log(apps.data?.applications);
}

// Get a download URL
const download = await client.getDownloadInfo('my-app', '2.1.0');
if (download.success) {
  console.log(download.data?.url);
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

The API key and base URL can be changed on an existing client with `client.setApiKey(key)`
and `client.setBaseUrl(url)`.

## Methods

### Applications

#### listApplications

List all applications accessible to the API key.

```typescript
const result = await client.listApplications({
  search: 'my-app',
  tags: 'windows',
  page: 1,
  pageSize: 10
});

if (result.success) {
  console.log(result.data?.applications);
  console.log(result.meta?.pagination); // { page, limit, total, hasNext, hasPrevious }
}
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `search` | string | Search by name or description |
| `tags` | string | Filter by tag |
| `isActive` | boolean | Filter by active state |
| `page` | number | Page number (default 1) |
| `pageSize` | number | Items per page (default 20, max 100) |
| `sortBy` | `'name'` \| `'createdAt'` \| `'updatedAt'` | Sort field |
| `sortOrder` | `'asc'` \| `'desc'` | Sort direction |

#### getApplication

Get details for a specific application.

```typescript
const result = await client.getApplication('my-app');
```

#### getApplicationStats

Get download statistics for an application, optionally for a single version.

```typescript
const result = await client.getApplicationStats('my-app');
const forVersion = await client.getApplicationStats('my-app', '2.1.0');

if (result.success) {
  const { totalDownloads, uniqueCustomers, downloadsByVersion } = result.data!;
}
```

#### createApplication

Create an application (admin only).

```typescript
const result = await client.createApplication({
  applicationId: 'my-app',
  name: 'My App',
  description: 'Desktop client',
  tags: ['windows'],
  customerIds: ['cust_123']
});
```

#### updateApplicationCustomers

Grant or revoke customer access to an application (admin only).

```typescript
const result = await client.updateApplicationCustomers('my-app', {
  addCustomerIds: ['cust_456'],
  removeCustomerIds: ['cust_123']
});

if (result.success) {
  console.log(result.data?.customerIds); // access list after the change
}
```

#### deleteApplication

Soft delete an application (admin only). Its data is kept but hidden from listings.

```typescript
const result = await client.deleteApplication('my-app');
```

### Versions

#### listVersions

List all versions of an application. Pass `channel: 'Test'` to include disabled versions.

```typescript
const result = await client.listVersions('my-app');
const withDisabled = await client.listVersions('my-app', { channel: 'Test' });
```

#### listVersionFiles

List all files in a version.

```typescript
const result = await client.listVersionFiles('my-app', '2.1.0');
if (result.success) {
  for (const file of result.data!.files) {
    console.log(file.fileId, file.fileName, file.fileSize);
  }
}
```

#### updateVersion

Update a version's release notes or enable it for production downloads (admin only).

```typescript
const result = await client.updateVersion('my-app', '2.1.0', {
  isEnabled: true,
  releaseNotes: 'Fixes the installer on Windows 11',
  totpCode: '123456'
});
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `releaseNotes` | string \| null | Release notes (max 5000 characters); `null` or `''` clears them |
| `isEnabled` | boolean | Whether the version is available on the production channel |
| `totpCode` | string | 6-digit TOTP code. Required when setting `isEnabled: true` on a tenant with TOTP enabled |

The `UpdateVersionOptions` type also has `isActive` and `minimumClientVersion`, but the API
currently ignores them.

### Downloads

#### getDownloadInfo

Get a pre-signed download URL. The URL expires after 30 minutes.

```typescript
const result = await client.getDownloadInfo('my-app', '2.1.0');
if (result.success) {
  const { url, fileName, fileSize, checksum } = result.data!;
  console.log(`Download ${fileName} (${fileSize} bytes)`);
  console.log(url);
}
```

The full signature is `getDownloadInfo(applicationId, version, fileId?, options?)`. Pass a
`fileId` (from `listVersionFiles`) to download a file other than the main one, and
`{ channel: 'Test' }` to download a disabled version:

```typescript
const result = await client.getDownloadInfo('my-app', '2.2.0-beta', undefined, {
  channel: 'Test'
});
```

#### downloadFile

Download a file and return it as an `ArrayBuffer`. Throws if the download fails.

```typescript
import { writeFileSync } from 'node:fs';

const info = await client.getDownloadInfo('my-app', '2.1.0');
if (info.success) {
  const buffer = await client.downloadFile(info.data!.url);
  writeFileSync(info.data!.fileName, Buffer.from(buffer));
}
```

#### downloadFileStream

Download a file as a web `ReadableStream` (for large files). Throws if the download fails.

```typescript
import { createWriteStream } from 'node:fs';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import type { ReadableStream as NodeReadableStream } from 'node:stream/web';

const stream = await client.downloadFileStream(info.data!.url);
if (stream) {
  await pipeline(
    Readable.fromWeb(stream as NodeReadableStream<Uint8Array>),
    createWriteStream('output.exe')
  );
}
```

#### createShareLink

Create a shareable download link. `expiresInMinutes` defaults to 30; `fileId` is optional.

```typescript
const result = await client.createShareLink({
  applicationId: 'my-app',
  version: '2.1.0',
  expiresInMinutes: 60
});

if (result.success) {
  console.log(result.data?.shareUrl, result.data?.expiresAt);
}
```

### Customers (Admin)

#### listCustomers

List all customers.

```typescript
const result = await client.listCustomers();
```

#### updateCustomer

Update a customer's name, notes or active state.

```typescript
const result = await client.updateCustomer('cust_123', {
  name: 'New Name',
  isActive: true
});
```

#### regenerateCustomerKey

Regenerate a customer's API key. The new key is only returned once.

```typescript
const result = await client.regenerateCustomerKey('cust_123');
if (result.success) {
  console.log('New API key:', result.data?.apiKey);
}
```

### Activity (Admin)

#### listActivity

List recent uploads and downloads.

```typescript
const result = await client.listActivity({
  type: 'downloads',
  customerId: 'cust_123',
  limit: 50
});
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `type` | `'uploads'` \| `'downloads'` \| `'all'` | Activity type |
| `limit` | number | Maximum items (default 50, max 100) |
| `customerId` | string | Only activity for this customer |
| `startDate` | string | ISO 8601 start of the range |
| `endDate` | string | ISO 8601 end of the range |

## Error Handling

All API methods (everything except `downloadFile` and `downloadFileStream`) return an
`ApiResponse` instead of throwing:

```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
    timestamp?: string;
  };
  meta?: {
    requestId: string;
    pagination?: { page: number; limit: number; total: number; hasNext: boolean; hasPrevious: boolean };
  };
}
```

Example error handling:

```typescript
const result = await client.getApplication('unknown-app');

if (!result.success) {
  console.error(`Error ${result.error?.code}: ${result.error?.message}`);
  if (result.error?.code === 'NOT_FOUND') {
    console.log('Application does not exist');
  }
}
```

Error codes from the server are upper case (`BAD_REQUEST`, `UNAUTHORIZED`, `NOT_FOUND`, …).
The client adds `TIMEOUT` when a request exceeds `timeout`, and `NETWORK_ERROR` when the
request fails or the response is not JSON.

## TypeScript Support

The SDK is written in TypeScript and includes full type definitions. All option and response
types are exported:

```typescript
import type {
  ApplicationInfo,
  VersionInfo,
  VersionFile,
  DownloadInfo,
  CustomerInfo,
  ActivityItem,
  ListApplicationsOptions,
  // ... more types
} from '@bindist/client';
```
