# Delphi SDK

The official Delphi/Object Pascal client for the BinDist API. Compatible with Delphi 10.3+ and modern Object Pascal.

## Installation

Copy the following units to your project:

- `AppDist.Interfaces.pas` - Type definitions and interface
- `AppDist.ClientV1.pas` - Client implementation
- `AppDist.Factory.pas` - Factory function

The units are located in the `api/delphi/` directory.

## Quick Start

```pascal
uses
  AppDist.Interfaces, AppDist.Factory;

var
  Client: IAppDistClient;
  Response: TApiResponse<TArray<TApplicationInfo>>;
begin
  // Create client instance
  Client := CreateAppDistClient;
  Client.SetBaseUrl('https://api.bindist.eu');
  Client.SetApiKey('YOUR_API_KEY');

  // List applications
  Response := Client.ListApplications;
  if Response.Success then
  begin
    for var App in Response.Data do
      WriteLn(Format('%s - %s (v%s)', [App.ApplicationId, App.Name, App.LatestVersion]));
  end
  else
    WriteLn('Error: ' + Response.Error.Message);
end;
```

## Types

### TApplicationInfo

```pascal
TApplicationInfo = record
  ApplicationId: string;
  Name: string;
  Description: string;
  IsActive: Boolean;
  CreatedAt: TDateTime;
  UpdatedAt: TDateTime;
  LatestVersion: string;
  Tags: TArray<string>;
end;
```

### TVersionInfo

```pascal
TVersionInfo = record
  VersionId: string;
  ApplicationId: string;
  Version: string;
  ReleaseNotes: string;
  IsActive: Boolean;
  CreatedAt: TDateTime;
  UpdatedAt: TDateTime;
  FileSize: Int64;
  DownloadCount: Integer;
  RequiredTier: string;
  MinimumClientVersion: string;
end;
```

### TVersionFile

```pascal
TVersionFile = record
  FileId: string;
  FileName: string;
  FileType: string;    // MAIN, DEPENDENCY, CONFIGURATION, DOCUMENTATION
  FileSize: Int64;
  Checksum: string;
  Order: Integer;
  Description: string;
end;
```

### TDownloadInfo

```pascal
TDownloadInfo = record
  DownloadId: string;
  Url: string;
  ExpiresAt: TDateTime;
  FileName: string;
  FileSize: Int64;
  Checksum: string;
end;
```

### TApiResponse

Generic wrapper for all API responses:

```pascal
TApiResponse<T> = record
  Success: Boolean;
  Data: T;
  Error: TApiError;
  Pagination: TPagination;
  RequestId: string;
end;
```

### TApiError

```pascal
TApiError = record
  Code: string;
  Message: string;
  StatusCode: Integer;
  Timestamp: string;
end;
```

## Methods

### ListApplications

List all accessible applications.

```pascal
// Simple call
var Response := Client.ListApplications;

// With options
var Options: TListApplicationsOptions;
Options.Search := 'my-app';
Options.PageSize := 10;
var Response := Client.ListApplications(Options);
```

**Options:**

| Field | Type | Description |
|-------|------|-------------|
| `Page` | Integer | Page number |
| `PageSize` | Integer | Items per page |
| `Search` | string | Search by name/description |
| `Tags` | string | Filter by tag |
| `IsActive` | Boolean | Filter by active status |
| `IsActiveSet` | Boolean | Whether IsActive filter is set |
| `SortBy` | string | Sort field |
| `SortOrder` | string | 'asc' or 'desc' |

### GetApplication

Get details for a specific application.

```pascal
var Response := Client.GetApplication('my-app');
if Response.Success then
begin
  WriteLn('Name: ' + Response.Data.Name);
  WriteLn('Latest: ' + Response.Data.LatestVersion);
end;
```

### ListVersions

List all versions for an application.

```pascal
var Response := Client.ListVersions('my-app');
if Response.Success then
begin
  for var Ver in Response.Data do
    WriteLn(Format('%s - %d bytes', [Ver.Version, Ver.FileSize]));
end;
```

### ListVersionFiles

List all files in a specific version.

```pascal
var Response := Client.ListVersionFiles('my-app', '2.1.0');
if Response.Success then
begin
  for var F in Response.Data do
    WriteLn(Format('%s (%s) - %d bytes', [F.FileName, F.FileType, F.FileSize]));
end;
```

### GetDownloadInfo

Get a pre-signed download URL.

```pascal
// Get default file
var Response := Client.GetDownloadInfo('my-app', '2.1.0');

// Get specific file
var Response := Client.GetDownloadInfo('my-app', '2.1.0', 'file-id');

if Response.Success then
begin
  WriteLn('URL: ' + Response.Data.Url);
  WriteLn('Expires: ' + DateTimeToStr(Response.Data.ExpiresAt));
end;
```

### DownloadFile

Download a file to disk.

```pascal
var DownloadResponse := Client.GetDownloadInfo('my-app', '2.1.0');
if DownloadResponse.Success then
begin
  if Client.DownloadFile(DownloadResponse.Data.Url, 'C:\Downloads\my-app.exe') then
    WriteLn('Download complete!')
  else
    WriteLn('Download failed: ' + Client.GetLastError);
end;
```

### DownloadFileToStream

Download a file to a stream.

```pascal
var
  Stream: TMemoryStream;
  DownloadResponse: TApiResponse<TDownloadInfo>;
begin
  DownloadResponse := Client.GetDownloadInfo('my-app', '2.1.0');
  if DownloadResponse.Success then
  begin
    Stream := TMemoryStream.Create;
    try
      if Client.DownloadFileToStream(DownloadResponse.Data.Url, Stream) then
      begin
        Stream.Position := 0;
        // Process stream...
      end;
    finally
      Stream.Free;
    end;
  end;
end;
```

### GetLastError

Get the last error message when a method returns False.

```pascal
if not Client.DownloadFile(Url, Path) then
  ShowMessage('Error: ' + Client.GetLastError);
```

## Complete Example

```pascal
program DownloadLatestVersion;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  AppDist.Interfaces,
  AppDist.Factory;

var
  Client: IAppDistClient;
  AppsResponse: TApiResponse<TArray<TApplicationInfo>>;
  VersionsResponse: TApiResponse<TArray<TVersionInfo>>;
  DownloadResponse: TApiResponse<TDownloadInfo>;
  App: TApplicationInfo;
  LatestVersion: string;
  OutputPath: string;
begin
  try
    // Initialize client
    Client := CreateAppDistClient;
    Client.SetBaseUrl('https://api.bindist.eu');
    Client.SetApiKey(GetEnvironmentVariable('BINDIST_API_KEY'));

    // Get application
    AppsResponse := Client.GetApplication('my-app');
    if not AppsResponse.Success then
    begin
      WriteLn('Error: ' + AppsResponse.Error.Message);
      Exit;
    end;

    App := AppsResponse.Data;
    LatestVersion := App.LatestVersion;
    WriteLn(Format('Found %s v%s', [App.Name, LatestVersion]));

    // Get download URL
    DownloadResponse := Client.GetDownloadInfo(App.ApplicationId, LatestVersion);
    if not DownloadResponse.Success then
    begin
      WriteLn('Error: ' + DownloadResponse.Error.Message);
      Exit;
    end;

    // Download file
    OutputPath := Format('C:\Downloads\%s', [DownloadResponse.Data.FileName]);
    WriteLn(Format('Downloading %s (%d bytes)...',
      [DownloadResponse.Data.FileName, DownloadResponse.Data.FileSize]));

    if Client.DownloadFile(DownloadResponse.Data.Url, OutputPath) then
      WriteLn('Download complete: ' + OutputPath)
    else
      WriteLn('Download failed: ' + Client.GetLastError);

  except
    on E: Exception do
      WriteLn('Exception: ' + E.Message);
  end;
end.
```

## Error Handling

Always check `Response.Success` before accessing `Response.Data`:

```pascal
var Response := Client.ListApplications;

if Response.Success then
begin
  // Use Response.Data
  for var App in Response.Data do
    ProcessApp(App);
end
else
begin
  // Handle error
  case Response.Error.Code of
    'UNAUTHORIZED': ShowMessage('Invalid API key');
    'NOT_FOUND': ShowMessage('Application not found');
    'FORBIDDEN': ShowMessage('Access denied');
  else
    ShowMessage(Response.Error.Message);
  end;
end;
```

## Thread Safety

The `TAppDistClientV1` class is **not** thread-safe. Create separate client instances for each thread:

```pascal
procedure TMyThread.Execute;
var
  Client: IAppDistClient;
begin
  Client := CreateAppDistClient;
  Client.SetBaseUrl('https://api.bindist.eu');
  Client.SetApiKey(FApiKey);

  // Use client in this thread only
end;
```

## Requirements

- Delphi 10.3 Rio or later
- RTL units: `System.Net.HttpClient`, `System.JSON`, `System.Generics.Collections`
