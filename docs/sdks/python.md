# Python SDK

The official Python client for the BinDist API. Aimed at **tooling and scripting** — release pipelines, internal CLIs, ad-hoc admin scripts — rather than embedding into a long-running application.

For a richer typed integration into a runtime, prefer the [Go SDK](go.md) (executable integration) or the [JavaScript SDK](javascript.md) (web).

Source: [github.com/BinDist/bindist-api-python](https://github.com/BinDist/bindist-api-python).

## Requirements

- Python 3.10+
- `requests`

## Installation

The package is not yet on PyPI. Install from source:

```bash
git clone https://github.com/BinDist/bindist-api-python.git
cd bindist-api-python
pip install -e .
```

## Quick Start

```python
from bindist import CustomerClient

client = CustomerClient("https://api.bindist.eu", "YOUR_API_KEY")

apps = client.list_applications()
if apps.success:
    for app in apps.data["applications"]:
        print(f"{app['name']} ({app['applicationId']})")
else:
    print(f"Error: {apps.error['message']}")
```

## Two clients

```python
from bindist import CustomerClient, AdminClient

client = CustomerClient("https://api.bindist.eu", "your-api-key")
admin = AdminClient("https://api.bindist.eu", "admin-api-key")
```

| Client | Purpose |
|---|---|
| `CustomerClient` | List applications and versions, fetch download URLs, download files, create share links, read stats. |
| `AdminClient` | Create and update applications, upload binaries (small or large), manage customers and API keys, list activity. |

Pick whichever matches the API key you have.

## Customer client

```python
# List applications (with optional filters)
client.list_applications(search="myapp", tags=["windows"], page=1, page_size=20)

# Get a single application
client.get_application("myapp")

# List versions (set test_channel=True to include disabled/pre-release)
client.list_versions("myapp", test_channel=True)

# List files in a version
client.list_version_files("myapp", "1.0.0")

# Get a download URL (file_id is optional, for multi-file versions)
client.get_download_url("myapp", "1.0.0")

# Create a share link (default 30 minutes, max 1440)
client.create_share_link("myapp", "1.0.0", expires_minutes=60)

# Download statistics
client.get_stats("myapp")
```

### Downloading files

`download_file` returns a `(bytes, metadata)` tuple, not an `ApiResponse`. It verifies the SHA256 checksum by default and raises `ValueError` on mismatch.

```python
content, metadata = client.download_file("myapp", "1.0.0")
with open(metadata["fileName"], "wb") as f:
    f.write(content)
print(f"Downloaded {metadata['fileName']} ({metadata['fileSize']} bytes)")

# Skip verification (not recommended)
content, metadata = client.download_file("myapp", "1.0.0", verify_checksum=False)

# Download from the test channel
content, metadata = client.download_file("myapp", "1.2.3-rc1", test_channel=True)
```

## Admin client

```python
# Create a customer (returns the new API key once)
customer = admin.create_customer(name="Acme Corp", notes="Enterprise customer")
print(customer.data["apiKey"])  # save it now — not retrievable later

# Create an application
admin.create_application(
    application_id="myapp",
    name="My Application",
    customer_ids=["customer-1"],
    description="A great application",
    tags=["windows", "desktop"],
)

# Upload a small file (< 10 MB) — single request
with open("app.exe", "rb") as f:
    admin.upload_small_file("myapp", "1.0.0", "app.exe", f.read(),
                            release_notes="Initial release")

# Upload a large file (>= 10 MB) — handles the pre-signed S3 flow internally
with open("large-app.exe", "rb") as f:
    admin.upload_large_file("myapp", "2.0.0", "large-app.exe", f.read(),
                            release_notes="Major update")

# Toggle release state / update notes
admin.update_version("myapp", "1.0.0", is_enabled=True,
                     release_notes="Updated release notes")

# Customers and activity
admin.update_customer("customer-1", name="New Name", is_active=True)
admin.delete_application("myapp")  # soft delete
admin.list_activity(activity_type="download", page=1)
admin.list_customers()
```

The two upload methods correspond to the [Upload Binary](../api/management.md#upload-binary) and [Large File Upload](../api/management.md#large-file-upload) endpoints. Use `upload_large_file` for anything ≥10 MB; it transparently calls `get_large_upload_url`, PUTs to S3, and then calls `complete_large_upload`.

## Response shape

Every method (except `download_file`) returns an `ApiResponse` dataclass:

```python
@dataclass
class ApiResponse:
    success: bool
    status_code: int
    data: dict | None
    error: dict | None
    meta: dict | None
    raw: dict
```

`data`, `error`, and `meta` mirror the JSON structure returned by the API. There are no typed model objects — you index into dicts (`response.data["applications"]`).

## Error handling

```python
response = client.list_applications()

if response.success:
    for app in response.data["applications"]:
        process(app)
else:
    print(f"Error {response.status_code}: {response.error.get('message')}")
    print(f"Code: {response.error.get('code')}")
```

If the response body isn't valid JSON (for example, an HTML error page from a proxy), the SDK still produces an `ApiResponse` with `success=False`, `status_code` set to the underlying HTTP status, and `error={"message": <raw text>}`.

## License

The Python SDK is released under the MIT License.
