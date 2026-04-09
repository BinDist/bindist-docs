# Authentication

BinDist uses API key authentication to secure all API endpoints.

## API Key Format

The shape of the API key depends on which deployment you're talking to.

### Hosted (api.bindist.eu)

On the hosted, multi-tenant deployment, API keys follow the format `{tenantId}.{secret}`:

- **Tenant ID**: A UUID issued when your customer account is created.
- **Secret**: A randomly generated secret, returned once when the key is provisioned.

The two are joined by a literal dot. Example:

```
14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere
```

A bare secret without the tenant prefix will be rejected.

### Self-hosted (single-tenant)

On a self-hosted, single-tenant deployment there is only one possible tenant, so the tenant prefix is unnecessary. You can pass just the secret as your API key.

## Sending Your API Key

Include your API key in the `Authorization` header using Bearer authentication:

```bash
Authorization: Bearer YOUR_API_KEY
```

Alternatively, you can use the `X-API-Key` header:

```bash
X-API-Key: YOUR_API_KEY
```

## Example Request

=== "curl"

    ```bash
    curl -H "Authorization: Bearer 14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere" \
      https://api.bindist.eu/v1/applications
    ```

=== "JavaScript"

    ```javascript
    const response = await fetch('https://api.bindist.eu/v1/applications', {
      headers: {
        'Authorization': 'Bearer 14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere'
      }
    });
    ```

=== "PowerShell"

    ```powershell
    $headers = @{
      "Authorization" = "Bearer 14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere"
    }
    Invoke-RestMethod -Uri "https://api.bindist.eu/v1/applications" -Headers $headers
    ```

## Key Types

BinDist uses two types of API keys:

### Admin Keys

Admin keys provide full access to manage your account:

- Create and manage applications
- Upload new versions
- Create customer API keys
- View activity logs
- Manage backups

### Customer Keys

Customer keys provide read-only access:

- List accessible applications
- List versions
- Download files

## Security Best Practices

!!! danger "Never Expose Your API Key"
    - Don't commit API keys to version control
    - Don't include API keys in client-side JavaScript
    - Use environment variables or secure secret management

!!! tip "Regenerate Compromised Keys"
    If you suspect your API key has been compromised, regenerate it immediately from the Account page.

### Storing API Keys Securely

=== "Environment Variables"

    ```bash
    export BINDIST_API_KEY="14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere"
    ```

    ```javascript
    const apiKey = process.env.BINDIST_API_KEY;
    ```

=== ".env File"

    ```
    BINDIST_API_KEY=14632221-b1b6-4eec-844a-39f60c7f1523.xYz789SecretKeyHere
    ```

    !!! warning
        Add `.env` to your `.gitignore` file!

=== "Secret Manager"

    For production environments, use a secret manager like AWS Secrets Manager, HashiCorp Vault, or similar.

## Error Responses

### Missing API Key

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing authentication token"
  }
}
```

### Invalid API Key

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid API key"
  }
}
```

### Inactive Account

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Account is inactive"
  }
}
```
