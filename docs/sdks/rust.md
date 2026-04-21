# Rust SDK

The official Rust client for the BinDist API. Async, built on `reqwest` with `rustls-tls` (no OpenSSL), and focused on the **customer-facing** endpoints — listing applications and versions, browsing version files, minting pre-signed download URLs, and creating public share links.

The Rust crate does not ship an admin client. For administrative operations (creating applications, uploading binaries, managing customers), use the [Go SDK](go.md) or call the [Management API](../api/management.md) directly.

Source: [github.com/BinDist/bindist-api-rust](https://github.com/BinDist/bindist-api-rust). Published to [crates.io](https://crates.io/crates/bindist) as `bindist`; API docs on [docs.rs](https://docs.rs/bindist).

## Requirements

- Rust 1.80+
- An async runtime (examples use `tokio`)

## Installation

```toml
[dependencies]
bindist = "0.1"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
```

## API key format

The shape of the API key depends on which deployment you're talking to:

- **Hosted (`api.bindist.eu`, multi-tenant):** `{tenant_id}.{secret}` — the tenant ID (a UUID issued when your customer account is created) and the secret (returned once when the key is provisioned), joined by a literal dot. A bare secret will be rejected.
- **Self-hosted (single-tenant):** just the secret. There's only one possible tenant, so the prefix is unnecessary.

```rust
use bindist::Client;

// Hosted
let api_key = format!("{tenant_id}.{secret}");
let client = Client::new("https://api.bindist.eu", api_key)?;

// Self-hosted
let client = Client::new("https://bindist.internal.example.com", secret)?;
```

## Quick Start

```rust
use bindist::{Client, GetDownloadInfoOptions, ListApplicationsOptions, ListVersionsOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = Client::new("https://api.bindist.eu", "YOUR_API_KEY")?;

    let apps = client
        .list_applications(&ListApplicationsOptions::default())
        .await?;
    for app in &apps.items {
        println!("{} ({})", app.name, app.application_id);
    }

    let versions = client
        .list_versions("myapp", &ListVersionsOptions::default())
        .await?;
    for v in &versions.items {
        println!("  {} ({} bytes)", v.version, v.file_size);
    }

    let info = client
        .get_download_info("myapp", "1.0.0", &GetDownloadInfoOptions::default())
        .await?;
    println!("Download URL: {}", info.url);

    Ok(())
}
```

## Methods

All methods are `async` and return `Result<T, bindist::Error>`.

### List applications

```rust
use bindist::ListApplicationsOptions;

let page = client
    .list_applications(&ListApplicationsOptions {
        search: Some("myapp".into()),
        tag: Some("windows".into()),
        page: Some(1),
        limit: Some(20),
        ..Default::default()
    })
    .await?;
```

Returns a `Page<Vec<Application>>` — use `page.items` for the results and `page.pagination` for cursor/has-more metadata.

### Get application

```rust
let app = client.get_application("myapp").await?;
println!("{}: {}", app.name, app.description.unwrap_or_default());
```

### List versions and version files

```rust
use bindist::ListVersionsOptions;

let versions = client
    .list_versions("myapp", &ListVersionsOptions::default())
    .await?;

let files = client.list_version_files("myapp", "1.0.0").await?;
```

### Get a download URL

```rust
use bindist::GetDownloadInfoOptions;

let info = client
    .get_download_info(
        "myapp",
        "1.0.0",
        &GetDownloadInfoOptions::default(),
    )
    .await?;

println!("URL: {}", info.url);
println!("Expires: {}", info.expires_at);
```

Set `GetDownloadInfoOptions.file_id` to target a specific file on multi-file versions. When omitted, the `MAIN` file is returned.

### Download a file

The `download` helper fetches the pre-signed URL and streams the bytes into memory in one call:

```rust
let (info, bytes) = client
    .download("myapp", "1.0.0", &GetDownloadInfoOptions::default())
    .await?;

std::fs::write(&info.file_name, &bytes)?;
```

For custom streaming (large files, progress bars, direct-to-disk writes), call `get_download_info` and drive the download yourself with `reqwest`.

### Create a share link

```rust
use bindist::CreateShareLinkRequest;

let share = client
    .create_share_link(&CreateShareLinkRequest {
        application_id: "myapp".into(),
        version: "1.0.0".into(),
        file_id: None,
        expires_in_minutes: Some(60),
    })
    .await?;

println!("Share URL: {}", share.share_url);
```

`expires_in_minutes` accepts 5–1440 and defaults to 30 when omitted.

## Release channels

Versions can be published on non-default channels — for example, disabled and pre-release builds sit on the `Test` channel. Pass `channel: Some(Channel::Test)` in the options struct to send the `X-Channel` header:

```rust
use bindist::{Channel, ListVersionsOptions, GetDownloadInfoOptions};

let versions = client
    .list_versions(
        "myapp",
        &ListVersionsOptions {
            channel: Some(Channel::Test),
            ..Default::default()
        },
    )
    .await?;

let info = client
    .get_download_info(
        "myapp",
        "1.2.3-rc1",
        &GetDownloadInfoOptions {
            channel: Some(Channel::Test),
            ..Default::default()
        },
    )
    .await?;
```

## Error handling

All API methods return `Result<T, bindist::Error>`. `Error::Api(ApiError)` covers both the server's structured error envelopes **and** non-2xx responses that never reach the API — responses from auth middleware, reverse proxies, load balancers, and gateway timeouts are normalized into the same shape.

For transport-level reactions, switch on `http_status`; for semantic ones, switch on `code`:

```rust
use bindist::Error;

match client.list_applications(&Default::default()).await {
    Ok(page) => { /* … */ }
    Err(Error::Api(api)) => match api.code.as_str() {
        "unauthorized" => eprintln!("bad or missing API key"),
        "rate_limited" => { /* back off and retry */ }
        _ => eprintln!("API error {} ({}): {}", api.http_status, api.code, api.message),
    },
    Err(other) => eprintln!("transport error: {other}"),
}
```

Derived codes for envelope-less responses include `unauthorized`, `forbidden`, `not_found`, `rate_limited`, `server_error`, and `http_error`.

## Custom HTTP client

`Client::new` builds a default `reqwest::Client` with `rustls-tls`. To inject your own (custom timeouts, proxies, middleware, user agent), use `Client::with_http_client`:

```rust
let http = reqwest::Client::builder()
    .timeout(std::time::Duration::from_secs(30))
    .user_agent("my-app/1.2.3")
    .build()?;

let client = Client::with_http_client("https://api.bindist.eu", "YOUR_API_KEY", http)?;
```

## License

The Rust SDK is released under the MIT License.
