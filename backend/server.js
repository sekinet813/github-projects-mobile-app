require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const fs = require('fs');

const app = express();
const PORT = 3000;

// CORS設定（Flutterアプリからのリクエストを許可）
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));
app.use(express.json());

// GitHub App設定
// 環境変数から読み取る
// GITHUB_APP_ID: GitHub App ID（整数）
// GITHUB_APP_PRIVATE_KEY_PATH: 秘密鍵ファイルのパス（オプション、PRIVATE_KEYが設定されている場合は不要）
// GITHUB_APP_PRIVATE_KEY: 秘密鍵の生の値（CI/コンテナ環境用、PRIVATE_KEY_PATHの代替）

// 環境変数の検証
const GITHUB_APP_ID = process.env.GITHUB_APP_ID;
const GITHUB_APP_PRIVATE_KEY_PATH = process.env.GITHUB_APP_PRIVATE_KEY_PATH;
const GITHUB_APP_PRIVATE_KEY = process.env.GITHUB_APP_PRIVATE_KEY;

if (!GITHUB_APP_ID || GITHUB_APP_ID.trim() === '') {
  console.error('❌ 環境変数 GITHUB_APP_ID が設定されていません');
  console.error('   起動前に環境変数 GITHUB_APP_ID を設定してください');
  console.error('   例: export GITHUB_APP_ID=2587071');
  process.exit(1);
}

const APP_ID = parseInt(GITHUB_APP_ID, 10);
if (isNaN(APP_ID)) {
  console.error('❌ 環境変数 GITHUB_APP_ID は整数である必要があります');
  console.error(`   現在の値: "${GITHUB_APP_ID}"`);
  process.exit(1);
}

if (!GITHUB_APP_PRIVATE_KEY && (!GITHUB_APP_PRIVATE_KEY_PATH || GITHUB_APP_PRIVATE_KEY_PATH.trim() === '')) {
  console.error('❌ 環境変数 GITHUB_APP_PRIVATE_KEY または GITHUB_APP_PRIVATE_KEY_PATH のいずれかが設定されていません');
  console.error('   起動前に以下のいずれかを設定してください:');
  console.error('   - GITHUB_APP_PRIVATE_KEY: 秘密鍵の生の値（CI/コンテナ環境推奨）');
  console.error('   - GITHUB_APP_PRIVATE_KEY_PATH: 秘密鍵ファイルのパス');
  console.error('   例: export GITHUB_APP_PRIVATE_KEY_PATH=./mobile-github-projects.2026-01-03.private-key.pem');
  process.exit(1);
}

// OAuth App 設定の検証（オプション、OAuth エンドポイントを使用する場合のみ必要）
const GITHUB_OAUTH_CLIENT_ID = process.env.GITHUB_OAUTH_CLIENT_ID;
const GITHUB_OAUTH_CLIENT_SECRET = process.env.GITHUB_OAUTH_CLIENT_SECRET;

if (!GITHUB_OAUTH_CLIENT_ID || !GITHUB_OAUTH_CLIENT_SECRET) {
  console.warn('⚠️  環境変数 GITHUB_OAUTH_CLIENT_ID または GITHUB_OAUTH_CLIENT_SECRET が設定されていません');
  console.warn('   OAuth エンドポイント（/oauth/client-id, /oauth/exchange）を使用する場合は設定してください');
  console.warn('   例: export GITHUB_OAUTH_CLIENT_ID=your_client_id');
  console.warn('   例: export GITHUB_OAUTH_CLIENT_SECRET=your_client_secret');
}

let PRIVATE_KEY;
if (GITHUB_APP_PRIVATE_KEY) {
  // 環境変数から直接読み取る（CI/コンテナ環境用）
  PRIVATE_KEY = GITHUB_APP_PRIVATE_KEY;
  // 改行文字がエスケープされている場合に対応
  PRIVATE_KEY = PRIVATE_KEY.replace(/\\n/g, '\n');
} else {
  // ファイルパスから読み取る
  try {
    PRIVATE_KEY = fs.readFileSync(GITHUB_APP_PRIVATE_KEY_PATH, 'utf8');
  } catch (error) {
    console.error('❌ 秘密鍵ファイルの読み込みに失敗しました:', error.message);
    console.error(`   ファイルパス: ${GITHUB_APP_PRIVATE_KEY_PATH}`);
    process.exit(1);
  }
}

/**
 * GitHub App JWTを生成
 * 
 * JWTは10分間有効で、GitHub APIの認証に使用されます
 */
function generateJWT() {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iat: now - 60, // 60秒前から有効（時刻ずれ対策）
      exp: now + 600, // 10分間有効
      iss: APP_ID, // GitHub App ID
    },
    PRIVATE_KEY,
    { algorithm: 'RS256' }
  );
}

/**
 * Installation Access Tokenを取得
 * 
 * @param {string} installationId - GitHub App Installation ID
 * @returns {Promise<{token: string, expiresAt?: string}>} Installation Access Tokenと有効期限
 */
async function getInstallationAccessToken(installationId) {
  const appJWT = generateJWT();
  
  try {
    const response = await axios.post(
      `https://api.github.com/app/installations/${installationId}/access_tokens`,
      {},
      {
        headers: {
          Authorization: `Bearer ${appJWT}`,
          Accept: 'application/vnd.github.v3+json',
        },
      }
    );
    
    const token = response.data.token;
    // GitHub APIレスポンスから有効期限を取得（expires_at または expiresAt）
    const expiresAt = response.data.expires_at || response.data.expiresAt;
    
    return {
      token,
      expiresAt: expiresAt || undefined
    };
  } catch (error) {
    if (error.response) {
      throw new Error(
        `GitHub API エラー: ${error.response.status} - ${JSON.stringify(error.response.data)}`
      );
    }
    throw error;
  }
}

/**
 * インストール一覧を取得
 * 
 * ユーザーがGitHub Appをインストールした場所（User/Organization/Repository）の一覧を取得
 */
async function getInstallations() {
  const appJWT = generateJWT();
  
  try {
    const response = await axios.get(
      'https://api.github.com/app/installations',
      {
        timeout: 5000,
        headers: {
          Authorization: `Bearer ${appJWT}`,
          Accept: 'application/vnd.github.v3+json',
          'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
        },
      }
    );
    
    return response.data;
  } catch (error) {
    if (error.response) {
      const status = error.response.status;
      const message = error.response.data?.message || 
                     error.response.data?.error || 
                     'リクエストに失敗しました';
      throw new Error(`GitHub API error: ${status} - ${message}`);
    }
    throw error;
  }
}

// ヘルスチェックエンドポイント
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Installation Access Token取得エンドポイント
app.post('/api/github/installation-token', async (req, res) => {
  try {
    const { installationId } = req.body;
    
    // installationIdの存在チェック
    if (!installationId) {
      return res.status(400).json({ 
        error: 'installationIdが必要です' 
      });
    }
    
    // installationIdのフォーマット検証（数値または有効な文字列パターン）
    const installationIdStr = String(installationId).trim();
    if (installationIdStr === '') {
      return res.status(400).json({ 
        error: 'installationIdが空です' 
      });
    }
    
    // 数値IDまたは有効な文字列パターン（数字のみ）をチェック
    const isValidNumericId = /^\d+$/.test(installationIdStr);
    if (!isValidNumericId) {
      return res.status(400).json({ 
        error: 'installationIdは数値である必要があります' 
      });
    }
    
    // Installation Access Tokenを取得（トークンと有効期限を含む）
    const { token, expiresAt } = await getInstallationAccessToken(installationIdStr);
    
    // GitHub APIから返された有効期限を使用、なければデフォルト値（1時間後）にフォールバック
    const finalExpiresAt = expiresAt 
      ? new Date(expiresAt).toISOString()
      : new Date(Date.now() + 3600000).toISOString();
    
    res.json({ 
      token,
      expiresAt: finalExpiresAt,
    });
  } catch (error) {
    console.error('❌ Installation Access Token取得エラー:', error);
    res.status(500).json({ 
      error: error.message || 'トークン取得に失敗しました' 
    });
  }
});

// インストール一覧取得エンドポイント
app.get('/api/github/installations', async (req, res) => {
  try {
    const installations = await getInstallations();
    
    res.json({ installations });
  } catch (error) {
    console.error('❌ インストール一覧取得エラー:', error);
    res.status(500).json({ 
      error: error.message || 'インストール一覧の取得に失敗しました' 
    });
  }
});

// ===== OAuth App 用エンドポイント =====

// OAuth Client ID 取得（Flutter 側で認可 URL 生成に使用）
app.get('/oauth/client-id', (req, res) => {
  const clientId = process.env.GITHUB_OAUTH_CLIENT_ID;
  
  if (!clientId) {
    return res.status(500).json({ 
      error: 'OAuth Client ID が設定されていません' 
    });
  }
  
  res.json({ client_id: clientId });
});

// OAuth authorization code を access token に交換
app.post('/oauth/exchange', async (req, res) => {
  try {
    const clientId = process.env.GITHUB_OAUTH_CLIENT_ID;
    const clientSecret = process.env.GITHUB_OAUTH_CLIENT_SECRET;
    const redirectUri = process.env.OAUTH_REDIRECT_URI || 'github-projects-mobile://callback';
    
    if (!clientId || !clientSecret) {
      return res.status(500).json({ 
        error: 'OAuth 設定が不完全です' 
      });
    }
    
    const { code, state, code_verifier } = req.body;
    
    // バリデーション
    if (!code) {
      return res.status(400).json({ 
        error: 'authorization code が必要です' 
      });
    }
    
    // state パラメータの検証は Flutter 側で実施
    
    // GitHub OAuth API でトークン交換（PKCE対応）
    const tokenRequest = {
      client_id: clientId,
      client_secret: clientSecret,
      code: code,
      redirect_uri: redirectUri,
    };
    
    // PKCE code_verifier が提供されている場合は追加
    if (code_verifier) {
      tokenRequest.code_verifier = code_verifier;
    }
    
    const tokenResponse = await axios.post(
      'https://github.com/login/oauth/access_token',
      tokenRequest,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
        },
      }
    );
    
    const tokenData = tokenResponse.data;
    
    // GitHub API はエラー時も 200 を返すことがある
    if (tokenData.error) {
      return res.status(400).json({ 
        error: `GitHub OAuth エラー: ${tokenData.error} - ${tokenData.error_description || ''}` 
      });
    }
    
    res.json({
      access_token: tokenData.access_token,
      token_type: tokenData.token_type || 'bearer',
      scope: tokenData.scope || '',
    });
  } catch (error) {
    console.error('❌ Token 交換エラー:', error);
    if (error.response) {
      return res.status(400).json({ 
        error: `Token 交換に失敗しました: ${error.response.status} - ${error.response.data}` 
      });
    }
    res.status(500).json({ 
      error: error.message || 'Token 交換に失敗しました' 
    });
  }
});

// エラーハンドリング
app.use((err, req, res, next) => {
  console.error('❌ サーバーエラー:', err);
  res.status(500).json({ 
    error: '内部サーバーエラーが発生しました' 
  });
});

app.listen(PORT, () => {
  console.log(`🚀 GitHub App Backend API が起動しました`);
  console.log(`📍 ポート: ${PORT}`);
  console.log(`🔗 http://localhost:${PORT}`);
  console.log(`\n📋 エンドポイント:`);
  console.log(`   GET  /health`);
  console.log(`   POST /api/github/installation-token`);
  console.log(`   GET  /api/github/installations`);
  if (GITHUB_OAUTH_CLIENT_ID && GITHUB_OAUTH_CLIENT_SECRET) {
    console.log(`   GET  /oauth/client-id`);
    console.log(`   POST /oauth/exchange`);
  }
});

