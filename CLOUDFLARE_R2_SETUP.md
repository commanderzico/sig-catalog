# Cloudflare R2 + Pages Setup for Sig Catalog

This project uses Cloudflare R2 for storing images and audio files (for scalability and stability with multiple users), and Cloudflare Pages for hosting the static frontend.

## 1. Create R2 Bucket

1. Go to Cloudflare Dashboard > R2 Object Storage > Create bucket
2. Bucket name: `sig-catalog-media` (or your choice)
3. After creation, go to the bucket > Settings > Public access
4. Enable "Public" (or use a Worker for more control later)
5. Note the Public URL, e.g.:
   - `https://pub-xxxxx.r2.dev` (if using r2.dev)
   - Or set a custom domain like `media.yourdomain.com`

## 2. Upload Media to R2

Use rclone (recommended for folders with Korean filenames).

### Install rclone (if not installed)
```bash
brew install rclone
```

### Configure rclone for R2 (one time)
```bash
rclone config
```
- Select "n" for new remote
- Name: `r2`
- Type: `s3`
- Provider: `Cloudflare`
- env_auth: false
- access_key_id: your R2 access key (from R2 dashboard > Manage R2 API tokens)
- secret_access_key: your secret
- region: auto
- endpoint: https://<your-account-id>.r2.cloudflarestorage.com
- location_constraint: 
- acl: 
- Save.

### Upload images
```bash
rclone copy /Users/kim/Desktop/음원전체/이미지파일/ r2:sig-catalog-media/images/ --progress --transfers 10
```

### Upload audio (preserving folder structure under audio/)
```bash
rclone copy /Users/kim/Desktop/음원전체/1000~9999/ r2:sig-catalog-media/audio/1000~9999/ --progress --transfers 10
rclone copy /Users/kim/Desktop/음원전체/10000~50000/ r2:sig-catalog-media/audio/10000~50000/ --progress --transfers 10
rclone copy /Users/kim/Desktop/음원전체/5.7\ 뉴시그/ r2:sig-catalog-media/audio/5.7\ 뉴시그/ --progress --transfers 10
# Repeat for other 5.xx and 6.xx folders as needed
```

## 3. Update the Frontend Code

1. Open `index.html`
2. Find the line:
   ```js
   const R2_BASE = 'https://sig-catalog-media.YOUR-ACCOUNT-ID.r2.dev';
   ```
3. Replace `YOUR-ACCOUNT-ID` with your actual R2 public domain (e.g. `pub-abc123.r2.dev` or your custom domain).
4. Save and commit/push.

The site will now load images and audio from R2.

## 4. Deploy the Frontend to Cloudflare Pages (Recommended)

1. In Cloudflare Dashboard > Pages > Create a project > Connect to Git
2. Connect your GitHub repo `commanderzico/sig-catalog`
3. Build settings:
   - Framework preset: **None**
   - Build command: (leave empty)
   - Build output directory: `.`
   - **Deploy command**: (leave empty or remove if set to wrangler)
4. Save and deploy.

**Important**: Do not use custom "npx wrangler deploy" as deploy command, as it caused the .git bloat issue before.

## 5. (Optional) Better Stability with Worker + R2

For even better control (CORS, caching, hotlink protection, custom domain for media):

- Create a Worker that proxies R2.
- Example simple Worker code can be added later.

For now, public R2 bucket + Pages is sufficient and very stable.

## Notes

- Images are under `/images/` in the bucket.
- Audio preserves the original subfolder structure under `/audio/`.
- The Excel export and local files can stay as is for your use.
- For the site, media is now served from Cloudflare's fast global network.

After setup, hard refresh the site and test image load and audio play.

If you provide your R2 public URL, I can hardcode it in the code for you.

Run the upload commands above after configuring rclone.
