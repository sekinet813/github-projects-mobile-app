/**
 * Cloudflare Workers用のGitHub App認証API + OAuth App認証API
 * 
 * 環境変数（GitHub App用）:
 * - GITHUB_APP_ID: GitHub App ID
 * - GITHUB_APP_PRIVATE_KEY: GitHub Appの秘密鍵（PEM形式）
 * 
 * 環境変数（OAuth App用）:
 * - GITHUB_OAUTH_CLIENT_ID: OAuth App の Client ID
 * - GITHUB_OAUTH_CLIENT_SECRET: OAuth App の Client Secret
 * - OAUTH_REDIRECT_URI: 固定の redirect_uri（例: github-projects-mobile://callback）
 * 
 * Web Crypto APIを使用してJWTを生成
 * PKCS#8形式（PRIVATE KEY）の秘密鍵が必要
 * 変換方法: openssl pkcs8 -topk8 -nocrypt -in private-key.pem -out private-key-pkcs8.pem
 */

/**
 * Base64URLエンコード
 */
function base64UrlEncode(str) {
  return str
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * PKCS#1形式（RSA PRIVATE KEY）をPKCS#8形式に変換
 * GitHub Appの秘密鍵は通常PKCS#1形式なので、PKCS#8形式に変換する必要がある
 */
function convertPKCS1ToPKCS8(pkcs1Der) {
  // PKCS#1形式のDERデータからRSA鍵パラメータを抽出
  // これは簡略化された実装で、完全なASN.1パーサーではありません
  // 実際の実装では、より堅牢なASN.1パーサーを使用することを推奨
  
  // PKCS#8形式のヘッダーを追加
  // SEQUENCE { version INTEGER, algorithm AlgorithmIdentifier, privateKey OCTET STRING }
  // 簡略化: 実際にはASN.1エンコーディングが必要
  
  // より簡単な方法: 外部ツールで変換するか、Node.jsスクリプトで変換
  // ここでは、PKCS#1形式を直接使用できるように試みる
  return pkcs1Der;
}

/**
 * PEM形式の秘密鍵をCryptoKeyに変換
 * GitHub Appの秘密鍵はPKCS#1形式（RSA PRIVATE KEY）なので、
 * PKCS#8形式に変換する必要がある
 */
async function importPrivateKey(pemKey) {
  // PEM形式からヘッダーとフッターを削除
  const pemHeader = '-----BEGIN RSA PRIVATE KEY-----';
  const pemFooter = '-----END RSA PRIVATE KEY-----';
  const pemHeader2 = '-----BEGIN PRIVATE KEY-----';
  const pemFooter2 = '-----END PRIVATE KEY-----';
  
  let keyData = pemKey
    .replace(pemHeader, '')
    .replace(pemFooter, '')
    .replace(pemHeader2, '')
    .replace(pemFooter2, '')
    .replace(/\s/g, '');
  
  // Base64デコード
  const binaryDer = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));
  
  // PKCS#1形式かPKCS#8形式かを判定
  const isPKCS1 = pemKey.includes('-----BEGIN RSA PRIVATE KEY-----');
  
  if (isPKCS1) {
    // PKCS#1形式の場合、PKCS#8形式に変換する必要がある
    // 簡略化: 実際にはASN.1パーサー/エンコーダーが必要
    // ここでは、エラーメッセージを返す
    throw new Error(
      'PKCS#1形式の秘密鍵は直接サポートされていません。\n' +
      'PKCS#8形式に変換してください。\n' +
      '変換方法: openssl pkcs8 -topk8 -nocrypt -in private-key.pem -out private-key-pkcs8.pem'
    );
  } else {
    // PKCS#8形式の場合、直接インポート可能
    return await crypto.subtle.importKey(
      'pkcs8',
      binaryDer,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    );
  }
}

/**
 * JWTの署名を生成
 */
async function signJWT(payload, privateKey) {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };
  
  const encodedHeader = base64UrlEncode(
    btoa(JSON.stringify(header)).replace(/=/g, '')
  );
  const encodedPayload = base64UrlEncode(
    btoa(JSON.stringify(payload)).replace(/=/g, '')
  );
  
  const message = `${encodedHeader}.${encodedPayload}`;
  const messageBytes = new TextEncoder().encode(message);
  
  const signature = await crypto.subtle.sign(
    {
      name: 'RSASSA-PKCS1-v1_5',
    },
    privateKey,
    messageBytes
  );
  
  const encodedSignature = base64UrlEncode(
    btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/=/g, '')
  );
  
  return `${message}.${encodedSignature}`;
}

/**
 * GitHub App JWTを生成（Web Crypto API使用）
 */
async function generateJWT(appId, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iat: now - 60, // 60秒前から有効（時刻ずれ対策）
    exp: now + 600, // 10分間有効
    iss: appId,
  };
  
  try {
    const privateKey = await importPrivateKey(privateKeyPem);
    return await signJWT(payload, privateKey);
  } catch (error) {
    throw new Error(`JWT生成エラー: ${error.message}`);
  }
}

/**
 * Installation Access Tokenを取得
 */
async function getInstallationAccessToken(installationId, appId, privateKeyPem) {
  const appJWT = await generateJWT(appId, privateKeyPem);
  
  const response = await fetch(
    `https://api.github.com/app/installations/${installationId}/access_tokens`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${appJWT}`,
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
      },
    }
  );
  
  if (!response.ok) {
    const errorData = await response.text();
    throw new Error(
      `GitHub API エラー: ${response.status} - ${errorData}`
    );
  }
  
  const data = await response.json();
  return data.token;
}

/**
 * インストール一覧を取得
 */
async function getInstallations(appId, privateKeyPem) {
  const appJWT = await generateJWT(appId, privateKeyPem);
  
  const response = await fetch(
    'https://api.github.com/app/installations',
    {
      headers: {
        Authorization: `Bearer ${appJWT}`,
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
      },
    }
  );
  
  if (!response.ok) {
    const errorData = await response.text();
    throw new Error(
      `GitHub API エラー: ${response.status} - ${errorData}`
    );
  }
  
  return await response.json();
}

/**
 * CORSヘッダーを追加
 */
function addCorsHeaders(response) {
  const newHeaders = new Headers(response.headers);
  newHeaders.set('Access-Control-Allow-Origin', '*');
  newHeaders.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  newHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: newHeaders,
  });
}

/**
 * エラーレスポンスを生成
 */
function errorResponse(message, status = 500) {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { 'Content-Type': 'application/json' },
    }
  );
}

/**
 * 機密情報をマスク（ログ出力用）
 */
function maskSensitiveData(data) {
  if (typeof data === 'string') {
    // OAuth token や code をマスク
    return data
      .replace(/gho_[A-Za-z0-9_]+/g, 'gho_***')
      .replace(/ghu_[A-Za-z0-9_]+/g, 'ghu_***')
      .replace(/ghr_[A-Za-z0-9_]+/g, 'ghr_***')
      .replace(/[a-f0-9]{40}/g, '***'); // authorization code をマスク
  }
  if (typeof data === 'object' && data !== null) {
    const masked = { ...data };
    if ('access_token' in masked) masked.access_token = '***';
    if ('code' in masked) masked.code = '***';
    if ('client_secret' in masked) masked.client_secret = '***';
    return masked;
  }
  return data;
}

/**
 * OAuth authorization code を access token に交換（PKCE対応）
 */
async function exchangeCodeForToken(code, clientId, clientSecret, redirectUri, codeVerifier = null) {
  const body = {
    client_id: clientId,
    client_secret: clientSecret,
    code: code,
    redirect_uri: redirectUri,
  };
  
  // PKCE code_verifier が提供されている場合は追加
  if (codeVerifier) {
    body.code_verifier = codeVerifier;
  }
  
  const response = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `GitHub OAuth API エラー: ${response.status} - ${errorText}`
    );
  }

  const data = await response.json();
  
  // GitHub API はエラー時も 200 を返すことがある
  if (data.error) {
    throw new Error(
      `GitHub OAuth エラー: ${data.error} - ${data.error_description || ''}`
    );
  }

  return data;
}

/**
 * OAuth access token でユーザー情報を取得（テスト用）
 */
async function getUserInfo(accessToken) {
  const response = await fetch('https://api.github.com/user', {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitHub-Projects-Mobile-App/1.0',
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `GitHub API エラー: ${response.status} - ${errorText}`
    );
  }

  return await response.json();
}

/**
 * Cloudflare Workers エントリーポイント
 */
export default {
  async fetch(request, env) {
    // OPTIONSリクエスト（CORS preflight）の処理
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }
    
    const url = new URL(request.url);
    const path = url.pathname;
    
    try {
      // ヘルスチェック
      if (path === '/health' && request.method === 'GET') {
        const response = new Response(
          JSON.stringify({
            status: 'ok',
            timestamp: new Date().toISOString(),
          }),
          {
            headers: { 'Content-Type': 'application/json' },
          }
        );
        return addCorsHeaders(response);
      }

      // ===== OAuth App 用エンドポイント =====
      
      // OAuth Client ID 取得（Flutter 側で認可 URL 生成に使用）
      if (path === '/oauth/client-id' && request.method === 'GET') {
        const clientId = env.GITHUB_OAUTH_CLIENT_ID;
        
        if (!clientId) {
          return addCorsHeaders(
            errorResponse('OAuth Client ID が設定されていません', 500)
          );
        }
        
        const response = new Response(
          JSON.stringify({ client_id: clientId }),
          {
            headers: { 'Content-Type': 'application/json' },
          }
        );
        return addCorsHeaders(response);
      }
      
      // OAuth authorization code を access token に交換
      if (path === '/oauth/exchange' && request.method === 'POST') {
        const clientId = env.GITHUB_OAUTH_CLIENT_ID;
        const clientSecret = env.GITHUB_OAUTH_CLIENT_SECRET;
        const redirectUri = env.OAUTH_REDIRECT_URI || 'github-projects-mobile://callback';
        
        if (!clientId || !clientSecret) {
          return addCorsHeaders(
            errorResponse('OAuth 設定が不完全です', 500)
          );
        }
        let body;
        try {
          body = await request.json();
        } catch (e) {
          return addCorsHeaders(
            errorResponse('不正なリクエストボディです', 400)
          );
        }
        const { code, state, code_verifier } = body;
        
        // バリデーション
        if (!code) {
          return addCorsHeaders(
            errorResponse('authorization code が必要です', 400)
          );
        }
        
        // state パラメータの検証は Flutter 側で実施
        // （Workers 側では state を保存していないため）
        
        // redirect_uri の固定（セキュリティ対策）
        // 注意: GitHub API には redirect_uri を送る必要があるが、
        // 環境変数で固定された値を使用
        
        try {
          const tokenData = await exchangeCodeForToken(
            code,
            clientId,
            clientSecret,
            redirectUri,
            code_verifier // PKCE code_verifier を渡す
          );
          
          const response = new Response(
            JSON.stringify({
              access_token: tokenData.access_token,
              token_type: tokenData.token_type || 'bearer',
              scope: tokenData.scope || '',
            }),
            {
              headers: { 'Content-Type': 'application/json' },
            }
          );
          return addCorsHeaders(response);
        } catch (error) {
          console.error('❌ Token exchange error:', error.message);
          console.error('❌ Error stack:', error.stack);
          
          // エラーメッセージを返す（機密情報は含まれない）
          const errorMessage = error.message || 'Token 交換に失敗しました';
          return addCorsHeaders(
            errorResponse(errorMessage, 400)
          );
        }
      }
      
      // OAuth access token でユーザー情報を取得（テスト用）
      if (path === '/oauth/me' && request.method === 'GET') {
        const authHeader = request.headers.get('Authorization');
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          return addCorsHeaders(
            errorResponse('Authorization header が必要です', 401)
          );
        }
        
        const accessToken = authHeader.substring(7);
        
        try {
          const userInfo = await getUserInfo(accessToken);
          
          const response = new Response(
            JSON.stringify(userInfo),
            {
              headers: { 'Content-Type': 'application/json' },
            }
          );
          return addCorsHeaders(response);
        } catch (error) {
          console.error('❌ Get user info error:', error.message);
          return addCorsHeaders(
            errorResponse('ユーザー情報の取得に失敗しました', 401)
          );
        }
      }

      // ===== GitHub App 用エンドポイント（既存） =====
      
      // 環境変数の確認（GitHub App 用）
      const appId = env.GITHUB_APP_ID;
      const privateKeyPem = env.GITHUB_APP_PRIVATE_KEY;
      
      // Installation Access Token取得
      if (path === '/api/github/installation-token' && request.method === 'POST') {
        if (!appId || !privateKeyPem) {
          return addCorsHeaders(
            errorResponse('GitHub App設定が不完全です', 500)
          );
        }
        
        const body = await request.json();
        const { installationId } = body;
        
        if (!installationId) {
          return addCorsHeaders(
            errorResponse('installationIdが必要です', 400)
          );
        }
        
        // Validate installationId is a positive integer
        const parsedInstallationId = Number(installationId);
        if (
          !Number.isFinite(parsedInstallationId) ||
          !Number.isInteger(parsedInstallationId) ||
          parsedInstallationId <= 0
        ) {
          return addCorsHeaders(
            errorResponse('installationId must be a positive integer', 400)
          );
        }
        
        const token = await getInstallationAccessToken(
          parsedInstallationId,
          appId,
          privateKeyPem
        );
        
        const response = new Response(
          JSON.stringify({
            token,
            expiresAt: new Date(Date.now() + 3600000).toISOString(), // 1時間後
          }),
          {
            headers: { 'Content-Type': 'application/json' },
          }
        );
        return addCorsHeaders(response);
      }
      
      // インストール一覧取得
      if (path === '/api/github/installations' && request.method === 'GET') {
        if (!appId || !privateKeyPem) {
          return addCorsHeaders(
            errorResponse('GitHub App設定が不完全です', 500)
          );
        }
        
        const installations = await getInstallations(appId, privateKeyPem);
        
        const response = new Response(
          JSON.stringify({ installations }),
          {
            headers: { 'Content-Type': 'application/json' },
          }
        );
        return addCorsHeaders(response);
      }
      
      // 404
      return addCorsHeaders(
        errorResponse('Not Found', 404)
      );
    } catch (error) {
      console.error('❌ エラー:', error.message);
      // スタックトレースには機密情報が含まれる可能性があるため、メッセージのみ出力
      return addCorsHeaders(
        errorResponse('内部サーバーエラーが発生しました', 500)
      );
    }
  },
};

