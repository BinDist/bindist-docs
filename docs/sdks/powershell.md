# PowerShell Scripts

BinDist provides PowerShell scripts for Windows automation and CI/CD integration.

## Available Scripts

### Customer Scripts

Located in `scripts/tenant-scripts/`:

| Script | Description |
|--------|-------------|
| `List-Applications.ps1` | List all accessible applications |
| `List-Versions.ps1` | List versions for an application |
| `Download-Application.ps1` | Download a specific version |

### CI/CD Scripts

Located in `scripts/ci-scripts/`:

| Script | Description |
|--------|-------------|
| `Upload-Binary.ps1` | Upload a new version |
| `Create-Customer.ps1` | Create a new customer |

## Configuration

Set your API key as an environment variable:

```powershell
$env:BINDIST_API_KEY = "your-api-key-here"
```

Or create a `.env` file:

```
BINDIST_API_KEY=your-api-key-here
BINDIST_API_URL=https://api.bindist.eu
```

## Examples

### List Applications

```powershell
.\List-Applications.ps1

# With search filter
.\List-Applications.ps1 -Search "my-app"
```

**Output:**

```
Applications:
  my-app (My Application) - v2.1.0
  another-app (Another Application) - v1.0.0
```

### List Versions

```powershell
.\List-Versions.ps1 -ApplicationId "my-app"
```

**Output:**

```
Versions for my-app:
  2.1.0 - 15.0 MB - 450 downloads
  2.0.0 - 14.0 MB - 823 downloads
  1.5.0 - 12.5 MB - 250 downloads
```

### Download Application

```powershell
# Download latest version
.\Download-Application.ps1 -ApplicationId "my-app"

# Download specific version
.\Download-Application.ps1 -ApplicationId "my-app" -Version "2.0.0"

# Specify output path
.\Download-Application.ps1 -ApplicationId "my-app" -OutputPath "C:\Downloads"
```

### Upload Binary

```powershell
.\Upload-Binary.ps1 `
  -ApplicationId "my-app" `
  -Version "2.2.0" `
  -FilePath ".\build\my-app-2.2.0.exe" `
  -ReleaseNotes "Bug fixes and improvements"
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Download BinDist Application
  shell: pwsh
  env:
    BINDIST_API_KEY: ${{ secrets.BINDIST_API_KEY }}
  run: |
    .\scripts\tenant-scripts\Download-Application.ps1 `
      -ApplicationId "my-app" `
      -Version "${{ inputs.version }}" `
      -OutputPath "./downloads"
```

### Azure Pipelines

```yaml
- task: PowerShell@2
  displayName: 'Upload to BinDist'
  env:
    BINDIST_API_KEY: $(BINDIST_API_KEY)
  inputs:
    filePath: 'scripts/ci-scripts/Upload-Binary.ps1'
    arguments: >
      -ApplicationId "my-app"
      -Version "$(Build.BuildNumber)"
      -FilePath "$(Build.ArtifactStagingDirectory)/my-app.exe"
```

### Jenkins

```groovy
stage('Upload to BinDist') {
    steps {
        withCredentials([string(credentialsId: 'bindist-api-key', variable: 'BINDIST_API_KEY')]) {
            powershell '''
                .\scripts\ci-scripts\Upload-Binary.ps1 `
                    -ApplicationId "my-app" `
                    -Version "$env:BUILD_NUMBER" `
                    -FilePath ".\output\my-app.exe"
            '''
        }
    }
}
```

## Error Handling

Scripts return appropriate exit codes:

| Exit Code | Description |
|-----------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Authentication failed |
| 3 | Resource not found |
| 4 | Validation error |

Example error handling:

```powershell
$result = .\Download-Application.ps1 -ApplicationId "my-app"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Download failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
```

## Proxy Configuration

If you're behind a proxy:

```powershell
$env:HTTP_PROXY = "http://proxy.example.com:8080"
$env:HTTPS_PROXY = "http://proxy.example.com:8080"
```

Or configure in PowerShell:

```powershell
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("http://proxy.example.com:8080")
```
