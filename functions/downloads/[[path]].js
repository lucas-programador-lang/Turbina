// Cloudflare Pages Function
// Caminho no projeto: /functions/downloads/[[path]].js
// (a pasta "functions" fica na RAIZ do repositório, ao lado da pasta
// que você publica como site — NÃO dentro dela)
//
// O que isso faz:
// Intercepta qualquer pedido para /downloads/* e só entrega o arquivo
// se o User-Agent do pedido corresponder ao sistema operacional daquele
// arquivo. Ex: /downloads/turbina-mac.sh só é servido se o User-Agent
// indicar macOS; em qualquer outro caso, retorna 403 com uma página de
// erro no visual do site.
//
// LIMITE IMPORTANTE (leia antes de confiar nisso como "segurança"):
// User-Agent é enviado pelo próprio navegador de quem faz o pedido, e
// pode ser alterado por quem quiser (DevTools, extensões, curl -A,
// Postman, etc). Isso bloqueia quem simplesmente cola o link direto no
// navegador (o cenário que você descreveu), mas NÃO impede alguém
// deliberadamente tentando burlar a checagem. Não trate isso como
// controle de acesso real — é só fricção para o caso comum.

const OS_BY_FILE = {
  'turbina-windows.bat': 'win',
  'turbina-mac.sh': 'mac',
  'turbina-linux.sh': 'linux',
};

const OS_LABEL = {
  win: 'Windows',
  mac: 'macOS',
  linux: 'Linux',
};

// Mesmos ícones usados nos cards do site principal (index.html), pra manter
// a identidade visual consistente também na página de erro.
const OS_ICON = {
  win: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 5.5L10.5 4.4V11.3H3V5.5Z"/><path d="M11.4 4.3L21 3V11.2H11.4V4.3Z"/><path d="M3 12.2H10.5V19.1L3 18V12.2Z"/><path d="M11.4 12.2H21V20.5L11.4 19.2V12.2Z"/></svg>`,
  mac: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M16.7 2c.1 1.1-.3 2.2-1 3-.7.9-1.9 1.6-3 1.5-.2-1.1.3-2.2 1-3 .8-.9 2.1-1.5 3-1.5zM20.8 17c-.6 1.3-.9 1.9-1.6 3-1 1.5-2.5 3.4-4.3 3.4-1.6 0-2-1-4.1-1-2.2 0-2.6 1-4.2 1-1.8 0-3.2-1.7-4.2-3.2C-.1 16.6-.6 11 1.4 8c1.3-1.9 3.3-3 5.3-3 1.7 0 3 .9 4 .9.9 0 2.5-1.1 4.3-1 .7 0 2.7.3 4 2-2.2 1.3-3.4 3.6-3.2 6.1.2 2.4 1.8 4.1 4 4z"/></svg>`,
  linux: `<svg viewBox="0 0 24 24">
    <path d="M12 2.2c-3.6 0-6 3.4-6 8 0 4.6 2.3 8.4 6 9.6 3.7-1.2 6-5 6-9.6 0-4.6-2.4-8-6-8z" fill="#0a0a0a"/>
    <ellipse cx="12" cy="13.5" rx="3.6" ry="5.4" fill="#ffffff"/>
    <ellipse cx="9.4" cy="7.2" rx="1.7" ry="2" fill="#ffffff"/>
    <ellipse cx="14.6" cy="7.2" rx="1.7" ry="2" fill="#ffffff"/>
    <circle cx="9.6" cy="7.5" r=".6" fill="#0a0a0a"/>
    <circle cx="14.4" cy="7.5" r=".6" fill="#0a0a0a"/>
    <path d="M11 8.6h2l-1 1.8z" fill="#f5a623"/>
    <path d="M8.4 20.6c1 .9 2.4 1.1 3.6.6.3-.1.3-.5 0-.7-1.1.3-2.3.2-3.3-.4-.4-.2-.7.2-.3.5z" fill="#f5a623"/>
    <path d="M15.6 20.6c-1 .9-2.4 1.1-3.6.6-.3-.1-.3-.5 0-.7 1.1.3 2.3.2 3.3-.4.4-.2.7.2.3.5z" fill="#f5a623"/>
  </svg>`,
};

function detectOS(userAgent) {
  const ua = (userAgent || '').toLowerCase();
  if (ua.includes('mac')) return 'mac';
  if (ua.includes('win')) return 'win';
  if (ua.includes('linux') || ua.includes('x11') || ua.includes('ubuntu')) return 'linux';
  return null;
}

function forbiddenResponse(requiredOS, detectedOS) {
  const requiredLabel = OS_LABEL[requiredOS] || 'outro sistema';
  const detectedLabel = detectedOS ? OS_LABEL[detectedOS] : 'não identificado';
  const requiredIcon = OS_ICON[requiredOS] || '';
  const detectedIcon = detectedOS ? OS_ICON[detectedOS] : '';

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Download não disponível para o seu sistema · Turbina</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0a0c10;
    --bg-2: #12151c;
    --bg-3: #181c26;
    --ink: #edeff4;
    --muted: #8891a7;
    --muted-2: #5c6478;
    --cyan: #4fd1ff;
    --violet: #8c6dff;
    --win: #4cc2ff;
    --mac: #e8e8ed;
    --linux: #f5b700;
    --line: rgba(237, 239, 244, 0.08);
    --line-2: rgba(237, 239, 244, 0.14);
  }
  * { box-sizing: border-box; }
  html, body {
    margin: 0;
    min-height: 100vh;
    background: var(--bg);
    color: var(--ink);
    font-family: 'Inter', sans-serif;
    overflow-x: hidden;
  }
  body {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    position: relative;
  }

  /* orbs de fundo, mesma linguagem do site principal */
  .orb {
    position: fixed;
    border-radius: 50%;
    filter: blur(100px);
    pointer-events: none;
    z-index: 0;
  }
  .orb-1 { width: 480px; height: 480px; background: var(--violet); opacity: 0.28; top: -120px; left: -100px; }
  .orb-2 { width: 520px; height: 520px; background: var(--cyan); opacity: 0.18; bottom: -160px; right: -140px; }

  .vignette {
    position: fixed;
    inset: 0;
    z-index: 1;
    pointer-events: none;
    background: radial-gradient(ellipse 80% 70% at 50% 45%, transparent 55%, rgba(0,0,0,0.55) 100%);
  }

  .card {
    position: relative;
    z-index: 2;
    width: 100%;
    max-width: 460px;
    background: linear-gradient(160deg, rgba(18,21,28,0.85), rgba(24,28,38,0.85));
    border: 1px solid var(--line-2);
    border-radius: 24px;
    padding: 44px 38px;
    text-align: center;
    backdrop-filter: blur(20px);
    box-shadow: 0 20px 60px rgba(0,0,0,0.5);
    animation: fadeUp 0.5s cubic-bezier(.2,.8,.2,1);
  }
  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(14px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .icon-ring {
    width: 68px; height: 68px;
    margin: 0 auto 26px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(140,109,255,0.08);
    border: 1px solid rgba(140,109,255,0.28);
    box-shadow: 0 0 40px rgba(140,109,255,0.15);
  }
  .icon-ring svg { width: 30px; height: 30px; }
  .icon-ring.icon-win svg { color: var(--win); }
  .icon-ring.icon-mac svg { color: var(--mac); }
  .icon-ring.icon-linux { background: rgba(245,183,0,0.08); border-color: rgba(245,183,0,0.28); box-shadow: 0 0 40px rgba(245,183,0,0.12); }
  .icon-ring.icon-linux svg { width: 36px; height: 36px; }

  .eyebrow {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.72rem;
    letter-spacing: 0.02em;
    color: var(--cyan);
    border: 1px solid rgba(79,209,255,0.3);
    background: rgba(79,209,255,0.06);
    padding: 5px 13px;
    border-radius: 100px;
    margin-bottom: 20px;
  }
  .eyebrow .dot {
    width: 5px; height: 5px; border-radius: 50%;
    background: var(--cyan);
    box-shadow: 0 0 8px var(--cyan);
  }

  h1 {
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: 1.5rem;
    letter-spacing: -0.01em;
    margin: 0 0 12px;
  }
  h1 .accent {
    background: linear-gradient(100deg, var(--cyan), var(--violet) 70%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
  }

  p.lede {
    color: var(--muted);
    font-size: 0.95rem;
    line-height: 1.6;
    margin: 0 0 28px;
  }

  .meta-row {
    display: flex;
    gap: 10px;
    justify-content: center;
    margin-bottom: 30px;
    flex-wrap: wrap;
  }
  .meta-pill {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.74rem;
    color: var(--muted-2);
    border: 1px solid var(--line-2);
    background: rgba(237,239,244,0.03);
    padding: 6px 12px 6px 8px;
    border-radius: 100px;
  }
  .meta-pill strong { color: var(--ink); font-weight: 500; }
  .meta-pill svg { width: 14px; height: 14px; flex-shrink: 0; }
  .meta-pill.pill-win svg { color: var(--win); }
  .meta-pill.pill-mac svg { color: var(--mac); }

  .btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    font-family: 'Inter', sans-serif;
    font-weight: 600;
    font-size: 0.92rem;
    padding: 13px 26px;
    border-radius: 12px;
    text-decoration: none;
    background: linear-gradient(135deg, var(--cyan), var(--violet));
    color: #06080c;
    box-shadow: 0 8px 30px rgba(79,209,255,0.22);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }
  .btn:hover { transform: translateY(-2px); box-shadow: 0 12px 34px rgba(79,209,255,0.32); }

  .footer-note {
    margin-top: 26px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.7rem;
    color: var(--muted-2);
  }

  @media (max-width: 480px) {
    .card { padding: 34px 24px; border-radius: 20px; }
  }
</style>
</head>
<body>

  <div class="orb orb-1"></div>
  <div class="orb orb-2"></div>
  <div class="vignette"></div>

  <main class="card">
    <div class="icon-ring icon-${requiredOS}">
      ${requiredIcon}
    </div>

    <span class="eyebrow"><span class="dot"></span> ARQUIVO INCOMPATÍVEL</span>

    <h1>Este script é para <span class="accent">${requiredLabel}</span></h1>
    <p class="lede">O arquivo que você tentou baixar foi feito para outro sistema operacional e não vai funcionar no seu.</p>

    <div class="meta-row">
      <span class="meta-pill pill-${requiredOS}">${requiredIcon} arquivo: <strong>${requiredLabel}</strong></span>
      ${detectedOS ? `<span class="meta-pill pill-${detectedOS}">${detectedIcon} detectado: <strong>${detectedLabel}</strong></span>` : `<span class="meta-pill">detectado: <strong>${detectedLabel}</strong></span>`}
    </div>

    <a class="btn" href="/#scripts">
      <svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M8 1v10M4 8l4 4 4-4M2 14h12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
      Baixar o script certo para o meu sistema
    </a>

    <div class="footer-note">turbina · scripts de otimização de código aberto</div>
  </main>

</body>
</html>`;

  return new Response(html, {
    status: 403,
    headers: { 'content-type': 'text/html; charset=utf-8' },
  });
}

export async function onRequest(context) {
  const { request, next, params } = context;

  // params.path vem do padrão de rota [[path]] — pode ser array de segmentos
  const segments = Array.isArray(params.path) ? params.path : [params.path];
  const fileName = segments[segments.length - 1];

  const requiredOS = OS_BY_FILE[fileName];

  // arquivo não mapeado (algo que não é um dos 3 scripts) -> deixa passar normalmente
  if (!requiredOS) {
    return next();
  }

  const userAgent = request.headers.get('user-agent');
  const detected = detectOS(userAgent);

  if (detected !== requiredOS) {
    return forbiddenResponse(requiredOS, detected);
  }

  return next();
}
