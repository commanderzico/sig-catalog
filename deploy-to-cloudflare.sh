#!/bin/bash
set -e

echo "=== Sig Catalog: Deploy to Cloudflare (R2 + Pages) ==="
echo "Prerequisites: Run 'wrangler login' in your terminal first (opens browser)."
echo "This script assumes wrangler is authenticated and you have a Cloudflare account."

# 1. Create R2 bucket (idempotent)
BUCKET_NAME="sig-catalog-media"
echo "Creating R2 bucket: $BUCKET_NAME (if not exists)..."
wrangler r2 bucket create $BUCKET_NAME || echo "Bucket may already exist."

# 2. Upload media to R2
echo "Uploading images to R2..."
wrangler r2 object put $BUCKET_NAME/images --recursive --directory ./images --yes || echo "Trying rclone fallback if needed..."

echo "Uploading audio to R2 (preserving structure)..."
for dir in 1000~9999 10000~50000 5.* 6.*; do
  if [ -d "$dir" ]; then
    echo "Uploading $dir to audio/$dir ..."
    wrangler r2 object put $BUCKET_NAME/audio/$dir --recursive --directory "./$dir" --yes || true
  fi
done

# 3. Get R2 public URL (user must make bucket public in dashboard or note it)
echo ""
echo "IMPORTANT: Go to Cloudflare Dashboard > R2 > $BUCKET_NAME > Settings > Public Access"
echo "Enable 'Public' if not already. Copy the Public URL (e.g. https://pub-xxx.r2.dev or custom domain)."
read -p "Paste your R2 public base URL (no trailing slash): " R2_PUBLIC_URL

if [ -z "$R2_PUBLIC_URL" ]; then
  echo "R2 URL required. Exiting."
  exit 1
fi

# 4. Update index.html with real R2 URL
echo "Updating index.html with R2 URL..."
sed -i '' "s|https://sig-catalog-media.YOUR-ACCOUNT-ID.r2.dev|$R2_PUBLIC_URL|g" index.html

# 5. Deploy frontend to Cloudflare Pages (static, using .pagesignore to exclude .git)
echo "Deploying to Cloudflare Pages (static site)..."
# Use wrangler pages deploy with .pagesignore respected; deploy from root but .pagesignore excludes .git
wrangler pages deploy . --project-name=sig-catalog --branch=main --commit-dirty=true || echo "If this fails due to .git, use dashboard Git integration instead."

echo ""
echo "Done! Next steps:"
echo "1. Verify R2 bucket is public and files are uploaded."
echo "2. In Cloudflare Pages (if not using the above deploy): Connect your GitHub repo, set Build output directory to '.', no custom deploy command."
echo "3. Update any custom domain if needed."
echo "4. Test the site: images and audio should load from R2."
echo "Site should be at https://sig-catalog.pages.dev or your custom domain."
