# Go SDK

The official Go client for the BinDist API. Designed for **embedding BinDist into Go executables** — pulling versioned binaries down at runtime, verifying their checksums, and (for admin tooling) uploading new releases.

Source: [github.com/BinDist/bindist-api-go](https://github.com/BinDist/bindist-api-go).

## Requirements

- Go 1.21+

## Installation

```bash
go get github.com/BinDist/bindist-api-go
```

## Quick Start

```go
package main

import (
    "context"
    "fmt"

    bindist "github.com/BinDist/bindist-api-go"
)

func main() {
    ctx := context.Background()
    client := bindist.NewClient("https://api.bindist.eu", "YOUR_API_KEY")

    apps, err := client.ListApplications(ctx, nil)
    if err != nil {
        panic(err)
    }
    if !apps.Success {
        fmt.Printf("API error: %s\n", apps.Error.Message)
        return
    }
    for _, app := range apps.Data {
        fmt.Printf("%s (%s)\n", app.Name, app.ApplicationID)
    }
}
```

## Two clients

The package exposes two clients with different scopes:

| Client | Constructor | Purpose |
|---|---|---|
| `Client` | `NewClient(baseURL, apiKey)` | End-user / customer operations: list applications, list versions, fetch download URLs, download files, create share links, read stats. |
| `AdminClient` | `NewAdminClient(baseURL, adminAPIKey)` | Administrative operations: create/update/delete applications, upload binaries, manage customers and API keys, list activity. |

Both share the same response shape and error handling. Use whichever matches the API key you have.

## Customer client

### List applications

```go
apps, err := client.ListApplications(ctx, nil)

// With filters
apps, err = client.ListApplications(ctx, &bindist.ListApplicationsOptions{
    Search:   "myapp",
    Tags:     []string{"windows", "desktop"},
    Page:     1,
    PageSize: 10,
})
```

### Get application

```go
app, err := client.GetApplication(ctx, "myapp")
if app.Success {
    fmt.Printf("Name: %s\n", app.Data.Name)
    fmt.Printf("Description: %s\n", app.Data.Description)
}
```

### List versions and version files

```go
versions, err := client.ListVersions(ctx, "myapp")
files, err := client.ListVersionFiles(ctx, "myapp", "1.0.0")
```

### Get a download URL

```go
download, err := client.GetDownloadInfo(ctx, "myapp", "1.0.0", "")
if download.Success {
    fmt.Printf("URL: %s\n", download.Data.URL)
    fmt.Printf("Expires: %s\n", download.Data.ExpiresAt)
}
```

The fourth argument is a specific `fileID` for multi-file versions, or `""` to get the default file.

### Download a file

Two flavors:

```go
// Into memory, with optional checksum verification
content, metadata, err := client.DownloadFile(ctx, "myapp", "1.0.0", "", true)
os.WriteFile(metadata.FileName, content, 0644)

// Stream directly to an io.Writer (good for large files)
file, _ := os.Create("output.exe")
defer file.Close()
metadata, err = client.DownloadFileToWriter(ctx, "myapp", "1.0.0", "", file)
```

The fourth argument is the optional `fileID`; the fifth argument to `DownloadFile` is a `verifyChecksum` flag — when true, the SDK verifies the SHA256 checksum returned by the API and returns an error on mismatch.

### Create a share link

```go
share, err := client.CreateShareLink(ctx, "myapp", "1.0.0", "", 60)
if share.Success {
    fmt.Printf("Share URL: %s\n", share.Data.ShareURL)
}
```

The last argument is the lifetime of the link in minutes.

### Get download statistics

```go
stats, err := client.GetStats(ctx, "myapp")
if stats.Success {
    fmt.Printf("Total downloads: %d\n", stats.Data.TotalDownloads)
}
```

## Admin client

```go
admin := bindist.NewAdminClient("https://api.bindist.eu", "ADMIN_API_KEY")
```

### Create a customer and an application

```go
customer, _ := admin.CreateCustomer(ctx, "Acme Corp", "", "Enterprise customer")
fmt.Printf("API Key: %s\n", customer.Data.APIKey)

app, _ := admin.CreateApplication(ctx, bindist.CreateApplicationOptions{
    ApplicationID: "myapp",
    Name:          "My Application",
    CustomerIDs:   []string{customer.Data.CustomerID},
    Description:   "A great application",
    Tags:          []string{"windows", "desktop"},
})
```

### Upload a binary

The Go client has separate small/large upload methods. Use `UploadLargeFile` for anything ≥10 MB; it transparently handles the multi-step pre-signed upload flow described in the [Large File Upload API docs](../api/management.md#large-file-upload).

```go
content, _ := os.ReadFile("app.exe")

// Small files (< 10 MB) — single request
result, err := admin.UploadSmallFile(ctx, "myapp", "1.0.0", "app.exe", content, "Initial release")

// Large files (≥ 10 MB) — pre-signed S3 upload + completion
result, err = admin.UploadLargeFile(ctx, "myapp", "2.0.0", "app.exe", content, "Major update")
```

### Update version metadata

```go
isEnabled := true
releaseNotes := "Updated release notes"
_, err := admin.UpdateVersion(ctx, "myapp", "1.0.0", bindist.UpdateVersionOptions{
    IsEnabled:    &isEnabled,
    ReleaseNotes: &releaseNotes,
})
```

Pointer fields let you distinguish "leave unchanged" (`nil`) from "set to zero value".

### Manage customers and activity

```go
admin.UpdateCustomer(ctx, "customer-1", &newName, &isActive, nil)
admin.DeleteApplication(ctx, "myapp")  // soft delete

activity, _ := admin.ListActivity(ctx, "download", "", 1, 20)
customers, _ := admin.ListCustomers(ctx, 1, 20)
```

## Context support

Every method takes a `context.Context` as its first argument, so you get cancellation, deadlines, and timeouts for free:

```go
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

apps, err := client.ListApplications(ctx, nil)
if err != nil {
    if errors.Is(ctx.Err(), context.DeadlineExceeded) {
        log.Println("Request timed out")
    }
}
```

## Response shape

All methods return a generic `Response[T]`:

```go
type Response[T any] struct {
    Success    bool
    Data       T
    Error      *ApiError
    Meta       *Meta
    HTTPStatus int
}

type ApiError struct {
    Code       string
    Message    string
    HTTPStatus int
}

type Meta struct {
    RequestID  string
    Pagination *Pagination
}
```

## Error handling

Two distinct failure modes — handle both:

```go
response, err := client.ListApplications(ctx, nil)
if err != nil {
    // Network error, JSON parse failure, context cancellation, etc.
    log.Fatalf("Request failed: %v", err)
}
if !response.Success {
    // API returned an error envelope
    log.Printf("API error %d (%s): %s",
        response.HTTPStatus, response.Error.Code, response.Error.Message)
}
```

### Errors from outside the API envelope

Not every error reaches the API's structured error renderer. Responses from auth middleware, reverse proxies, load balancers, rate limiters, and gateway timeouts arrive with a plain body (or no body at all) and cannot be wrapped in the standard `{"success":false,"error":{...}}` envelope.

When the client sees a non-2xx response, it normalizes it into the same `Response[T]` shape, so you only need one code path. `Error.Code` is set from the HTTP status (`unauthorized`, `forbidden`, `not_found`, `rate_limited`, `server_error`, `http_error`, …) and `Message` is extracted from a bare `{"message":...}` body or falls back to `http.StatusText`. Switch on `HTTPStatus` for transport-level reactions, on `Error.Code` for semantic ones:

```go
if !response.Success {
    switch response.Error.Code {
    case "unauthorized":
        // Bad/missing API key — often from auth middleware, not the app.
    case "rate_limited":
        // Back off and retry.
    default:
        log.Printf("API error %d: %s", response.HTTPStatus, response.Error.Message)
    }
}
```

## Release channels

Versions can be published on different release channels. By default, requests return only versions on the production channel. Pass `WithChannel` to `ListVersions`, `GetDownloadInfo`, `DownloadFile`, or `DownloadFileToWriter` to access another channel — for example, the built-in `ChannelTest` exposes disabled and pre-release versions:

```go
versions, err := client.ListVersions(ctx, "myapp",
    bindist.WithChannel(bindist.ChannelTest))

content, metadata, err := client.DownloadFile(ctx, "myapp", "1.2.3-rc1", "", true,
    bindist.WithChannel(bindist.ChannelTest))
```

Internally, `WithChannel` sets the `X-Channel` HTTP header on the request.

## License

The Go SDK is released under the MIT License.
