#!/bin/bash

# Build and deploy MkDocs documentation to Scaleway Object Storage.
# Usage: ./deploy-docs.sh
#
# Required environment variables:
#   SCW_ACCESS_KEY      Scaleway API access key
#   SCW_SECRET_KEY      Scaleway API secret key
#   SCW_REGION          Scaleway region (e.g. fr-par)
#   SCW_S3_ENDPOINT     S3-compatible endpoint, e.g. https://s3.fr-par.scw.cloud
#   SCW_DOCS_BUCKET     Name of the docs bucket
#
# Tip: source these from a local .env file or pass them inline.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

: "${SCW_ACCESS_KEY:?SCW_ACCESS_KEY is not set}"
: "${SCW_SECRET_KEY:?SCW_SECRET_KEY is not set}"
: "${SCW_S3_ENDPOINT:?SCW_S3_ENDPOINT is not set (e.g. https://s3.fr-par.scw.cloud)}"
: "${SCW_DOCS_BUCKET:?SCW_DOCS_BUCKET is not set}"

echo "=== Deploying Documentation to Scaleway ==="
echo "Bucket:   $SCW_DOCS_BUCKET"
echo "Endpoint: $SCW_S3_ENDPOINT"
echo ""

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required but not installed."
    exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: aws CLI is required (used for S3-compatible upload)."
    exit 1
fi

if ! command -v mkdocs >/dev/null 2>&1; then
    echo "Installing MkDocs and dependencies..."
    pip3 install -r requirements.txt
fi

echo "Building documentation..."
mkdocs build --strict --clean

if [ ! -d "site" ]; then
    echo "ERROR: build failed - site directory not created"
    exit 1
fi

# Map Scaleway credentials onto AWS CLI env vars for the S3-compatible API.
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
export AWS_DEFAULT_REGION="${SCW_REGION:-fr-par}"

cd site

echo "Uploading HTML (short cache)..."
aws s3 sync . "s3://${SCW_DOCS_BUCKET}/" \
    --endpoint-url "$SCW_S3_ENDPOINT" \
    --acl public-read \
    --delete \
    --exclude "*" \
    --include "*.html" \
    --include "sitemap.xml" \
    --cache-control "max-age=300" \
    --content-type "text/html"

echo "Uploading CSS..."
aws s3 sync . "s3://${SCW_DOCS_BUCKET}/" \
    --endpoint-url "$SCW_S3_ENDPOINT" \
    --acl public-read \
    --exclude "*" \
    --include "*.css" \
    --cache-control "max-age=31536000" \
    --content-type "text/css"

echo "Uploading JavaScript..."
aws s3 sync . "s3://${SCW_DOCS_BUCKET}/" \
    --endpoint-url "$SCW_S3_ENDPOINT" \
    --acl public-read \
    --exclude "*" \
    --include "*.js" \
    --cache-control "max-age=31536000" \
    --content-type "application/javascript"

echo "Uploading fonts and images..."
aws s3 sync . "s3://${SCW_DOCS_BUCKET}/" \
    --endpoint-url "$SCW_S3_ENDPOINT" \
    --acl public-read \
    --exclude "*" \
    --include "*.woff" \
    --include "*.woff2" \
    --include "*.ttf" \
    --include "*.eot" \
    --include "*.svg" \
    --include "*.png" \
    --include "*.jpg" \
    --include "*.jpeg" \
    --include "*.gif" \
    --include "*.ico" \
    --include "*.webp" \
    --cache-control "max-age=31536000"

echo "Uploading remaining assets and pruning deleted files..."
aws s3 sync . "s3://${SCW_DOCS_BUCKET}/" \
    --endpoint-url "$SCW_S3_ENDPOINT" \
    --acl public-read \
    --delete \
    --cache-control "max-age=3600"

echo ""
echo "=== Deployment Complete ==="
echo "Bucket: s3://$SCW_DOCS_BUCKET/"
