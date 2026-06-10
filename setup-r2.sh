#!/bin/bash
set -e

echo "=== Cloudflare R2 Setup for Sig Catalog ==="
echo "This will help upload media to R2 and prepare the site."

# 1. Check/install rclone
if ! command -v rclone &> /dev/null; then
  echo "Installing rclone..."
  if command -v brew &> /dev/null; then
    brew install rclone
  else
    echo "Please install rclone manually: https://rclone.org/install/"
    exit 1
  fi
fi

echo ""
echo "Step 1: Create R2 bucket in Cloudflare Dashboard if not done:"
echo "  - Go to https://dash.cloudflare.com"
echo "  - R2 Object Storage > Create bucket"
echo "  - Name it e.g. 'sig-catalog-media'"
echo "  - Make it Public (Settings > Public access)"
echo "  - Note the Public URL (e.g. https://pub-xxx.r2.dev or your custom domain)"
echo ""
read -p "Enter your R2 public base URL (without trailing slash, e.g. https://pub-abc.r2.dev): " R2_URL

if [ -z "$R2_URL" ]; then
  echo "R2 URL required. Exiting."
  exit 1
fi

echo ""
echo "Step 2: Configure rclone for R2 (if not already):"
echo "Run: rclone config"
echo "  - New remote name: r2"
echo "  - Type: s3"
echo "  - Provider: Cloudflare"
echo "  - Access key: Your R2 API token key"
echo "  - Secret: Your R2 API token secret"
echo "  - Endpoint: https://<your-account-id>.r2.cloudflarestorage.com"
echo "  - Region: auto"
echo ""
read -p "Press enter when rclone remote 'r2' is configured for your bucket..."

# 3. Upload
BUCKET="sig-catalog-media"  # Change if different

echo "Uploading images..."
rclone copy ./images/ r2:$BUCKET/images/ --progress --transfers 8

echo "Uploading audio folders..."
for dir in 1000~9999 10000~50000 5.* 6.*; do
  if [ -d "$dir" ]; then
    echo "  Uploading $dir..."
    rclone copy "./$dir/" "r2:$BUCKET/audio/$dir/" --progress --transfers 8
  fi
done

echo ""
echo "Step 3: Update index.html with your R2 URL"
echo "Open index.html and set:"
echo "  const R2_BASE = '$R2_URL';"
echo ""
echo "Then commit and push to GitHub."

echo ""
echo "Step 4: Deploy frontend to Cloudflare Pages"
echo "  - Connect your GitHub repo to Cloudflare Pages"
echo "  - Build output directory: ."
echo "  - No custom deploy command (or empty)"
echo "  - Use .pagesignore (already present) to exclude .git etc."

echo ""
echo "Done! Your media is now on R2, served via Cloudflare's fast network."
echo "For even better control, consider a Worker in front of R2 later."
