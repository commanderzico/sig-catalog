/**
 * Sig Catalog Upload Worker
 * Allows multiple people to upload new images + audio to R2
 * with simple username + password protection.
 *
 * Deploy:
 *   npx wrangler deploy upload-worker.js \
 *     --name sig-catalog-upload \
 *     --compatibility-date 2025-06-10 \
 *     --r2 MEDIA=sig-catalog-media
 *
 * Then update index.html UPLOAD_API to your https://sig-catalog-upload.<your>.workers.dev
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS preflight (for browser fetch from Pages domain)
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    if (url.pathname === '/upload' && request.method === 'POST') {
      return handleUpload(request, env);
    }

    if (url.pathname === '/sigs' && request.method === 'GET') {
      return handleGetSigs(env);
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' }
    });
  },
};

// === Simple username/password auth ===
// IMPORTANT: Change these before deploying to production!
// For better security later, move passwords to Wrangler secrets
// and/or use KV to store hashed credentials.
const ALLOWED_USERS = {
  "no3miggi": "no3miggi292713!",
  // Add more users as needed:
  // "친구1": "pas3s3!$@523123",
};

function checkAuth(username, password) {
  if (!username || !password) return false;
  return ALLOWED_USERS[username] === password;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

async function handleUpload(request, env) {
  try {
    const form = await request.formData();

    const username = (form.get('username') || '').trim();
    const password = form.get('password') || '';
    const id = parseInt(form.get('id'), 10);
    const imageTitle = (form.get('image_title') || '').trim();
    const audioTitle = (form.get('audio_title') || '').trim();
    const period = (form.get('period') || '').trim();
    const audioFolder = (form.get('audio_folder') || '기타').trim();

    const imageFile = form.get('image');
    const audioFile = form.get('audio');

    // Auth
    if (!checkAuth(username, password)) {
      return json({ error: '인증 실패 (아이디/비밀번호 확인)' }, 401);
    }

    // Basic validation
    if (!id || !imageTitle || !imageFile) {
      return json({ error: '단가(ID), 이미지 제목, 이미지 파일은 필수입니다.' }, 400);
    }
    if (!audioFolder) {
      return json({ error: '오디오 폴더명을 입력해주세요.' }, 400);
    }

    const R2 = env.MEDIA; // R2 binding name (passed at deploy time)

    // === Upload files to R2 ===
    const imageKey = `images/${imageFile.name}`;
    await R2.put(imageKey, imageFile.stream(), {
      httpMetadata: {
        contentType: imageFile.type || 'image/png',
      },
    });

    let audioKey = null;
    if (audioFile && audioFile.size > 0) {
      audioKey = `audio/${audioFolder}/${audioFile.name}`;
      await R2.put(audioKey, audioFile.stream(), {
        httpMetadata: {
          contentType: 'audio/mpeg',
        },
      });
    }

    // === Read current master list from R2 ===
    let sigs = [];
    const existing = await R2.get('data/sigs.json');
    if (existing) {
      try {
        sigs = await existing.json();
      } catch (e) {
        console.error('Failed to parse existing sigs.json from R2');
      }
    }

    // Build new entry (matching the structure used in the catalog)
    const newEntry = {
      id: id,
      audio_title: audioTitle || null,
      audio_files: audioFile ? [audioFile.name] : [],
      primary_audio_name: audioFile ? audioFile.name : null,
      period: period || null,
      image_title: imageTitle,
      image_name: imageFile.name,
      image_ext: (imageFile.name.split('.').pop() || 'PNG').toUpperCase(),
      image_period: null,
      audio_path: audioKey ? `${audioFolder}/${audioFile.name}` : null,
    };

    // Remove old entry with same ID if exists (allow overwrite)
    sigs = sigs.filter(s => s.id !== id);
    sigs.push(newEntry);

    // Sort newest first (by id desc)
    sigs.sort((a, b) => (b.id || 0) - (a.id || 0));

    // === Write updated list back to R2 ===
    await R2.put('data/sigs.json', JSON.stringify(sigs, null, 2), {
      httpMetadata: {
        contentType: 'application/json',
      },
    });

    return json({
      success: true,
      message: '업로드 완료',
      entry: newEntry,
      image_url: `${imageKey}`,
      audio_url: audioKey || null,
    });

  } catch (err) {
    console.error('Upload error:', err);
    return json({ error: '서버 오류: ' + (err.message || err) }, 500);
  }
}

async function handleGetSigs(env) {
  try {
    const obj = await env.MEDIA.get('data/sigs.json');
    if (!obj) {
      return json([]);
    }
    const data = await obj.json();
    return json(data);
  } catch (e) {
    return json({ error: 'Failed to load sigs' }, 500);
  }
}
