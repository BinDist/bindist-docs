# Welcome to BinDist

BinDist is a secure, multi-tenant application distribution system built on serverless infrastructure. It provides API key-authenticated downloads with binary storage, version management, and tier-based access control.

## Features

- **Secure Distribution** - API key authentication with SHA-256 hashed storage
- **Version Management** - Track multiple versions with file metadata and checksums
- **Multi-File Support** - Distribute applications with dependencies, documentation, and configuration files
- **Tier-Based Access** - Control which customers can access specific versions
- **Download Analytics** - Track downloads with IP detection and activity logs
- **Backup & Recovery** - Automated backups with S3 (or compatible) archival lifecycle

## Quick Links

<div class="grid cards" markdown>

-   **Getting Started**

    ---

    Get up and running with BinDist in minutes

    [Quick Start](getting-started/quick-start.md)

-   **API Reference**

    ---

    Complete API documentation with examples

    [API Overview](api/overview.md)

-   **JavaScript SDK**

    ---

    Use our official JavaScript/TypeScript client

    [SDK Documentation](sdks/javascript.md)

-   **Upload Guide**

    ---

    Learn how to upload and manage applications

    [Uploading Applications](guides/uploading.md)

</div>

## API Base URL

All API requests should be made to:

```
https://api.bindist.eu/v1/
```

## Authentication

BinDist uses API key authentication. Include your API key in the `Authorization` header:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.bindist.eu/v1/applications
```

See [Authentication](getting-started/authentication.md) for more details.

## Support

- **Documentation**: You're reading it!
- **Email**: support@bindist.eu
- **Website**: [https://bindist.eu](https://bindist.eu)
