// Cloudflare Pages Function
// Caminho no projeto: /functions/downloads/[[path]].js
// (a pasta "functions" fica na RAIZ do repositório, ao lado da pasta
// que você publica como site — NÃO dentro dela)
//
// O que isso faz:
// Intercepta qualquer pedido para /downloads/* e só entrega o arquivo se:
//   1) o pedido NÃO vier de celular/tablet, e
//   2) o User-Agent do pedido corresponder ao sistema operacional daquele
//      arquivo. Ex: /downloads/turbina-mac.sh só é servido em macOS
//      desktop; em qualquer outro caso, retorna 403 com uma página de
//      erro no visual do site (uma mensagem se for mobile, outra se for
//      OS errado).
//
// LIMITE IMPORTANTE (leia antes de confiar nisso como "segurança"):
// User-Agent (e o Client Hint Sec-CH-UA-Mobile) são enviados pelo próprio
// navegador de quem faz o pedido, e podem ser alterados por quem quiser
// (DevTools, extensões, curl -A, Postman, etc). Isso bloqueia quem
// simplesmente cola o link direto no navegador do celular ou segura o
// botão e copia o link (o cenário que você descreveu), mas NÃO impede
// alguém deliberadamente tentando burlar a checagem. Não trate isso como
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
  linux: `<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <g transform="scale(0.24)">
      <path d="M50 6 C39 6 31 15 31 25.5 C31 30.5 32.8 34.5 35.5 37.8 C26 44.5 18.5 56.5 16.5 68 C14 82 18 94 50 94 C82 94 86 82 83.5 68 C81.5 56.5 74 44.5 64.5 37.8 C67.2 34.5 69 30.5 69 25.5 C69 15 61 6 50 6 Z" fill="#0a0a0a"/>
      <path d="M22 52 C12 57 6 68 8 79 C9.5 87 18 91 25.5 87.5 C30 85.5 31.5 78 29.5 69 C28 62 25.5 56 22 52Z" fill="#0a0a0a"/>
      <path d="M78 52 C88 57 94 68 92 79 C90.5 87 82 91 74.5 87.5 C70 85.5 68.5 78 70.5 69 C72 62 74.5 56 78 52Z" fill="#0a0a0a"/>
      <ellipse cx="83" cy="58" rx="7.5" ry="9" fill="#0a0a0a"/>
      <ellipse cx="50" cy="62" rx="19" ry="27" fill="#f5f5f5"/>
      <ellipse cx="41" cy="22" rx="7.2" ry="9" fill="#f2f2f2"/>
      <ellipse cx="59" cy="22" rx="7.2" ry="9" fill="#f2f2f2"/>
      <circle cx="42.3" cy="24.5" r="3.4" fill="#0a0a0a"/>
      <circle cx="57.7" cy="24.5" r="3.4" fill="#0a0a0a"/>
      <path d="M36 31.5 C36 27 42.5 24 50 24 C57.5 24 64 27 64 31.5 C64 37.5 58 41.5 50 41.5 C42 41.5 36 37.5 36 31.5Z" fill="#f5a623" stroke="#d1830f" stroke-width="1.3"/>
      <path d="M38.5 32.5 Q50 38.5 61.5 32.5" fill="none" stroke="#d1830f" stroke-width="1.4" stroke-linecap="round"/>
      <path d="M28 88 C22 89.5 18 94 21 97.5 C24 100.5 30 99 32.5 94.5 C34.5 91 32.5 87 28 88Z" fill="#f5a623" stroke="#d1830f" stroke-width="1"/>
      <path d="M72 88 C78 89.5 82 94 79 97.5 C76 100.5 70 99 67.5 94.5 C65.5 91 67.5 87 72 88Z" fill="#f5a623" stroke="#d1830f" stroke-width="1"/>
    </g>
  </svg>`,
};

// Ícone de "monitor/desktop", usado na página de erro específica de mobile
const MONITOR_ICON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4" width="19" height="13" rx="2"/><path d="M8 21h8M12 17v4"/></svg>`;

function detectOS(userAgent) {
  const ua = (userAgent || '').toLowerCase();
  if (ua.includes('mac')) return 'mac';
  if (ua.includes('win')) return 'win';
  if (ua.includes('linux') || ua.includes('x11') || ua.includes('ubuntu')) return 'linux';
  return null;
}

// Server-side: checa mobile/tablet ANTES de qualquer coisa. Isso importa
// porque iPhone/iPad mandam "like Mac OS X" no User-Agent (ua.includes('mac')
// dá true) e Android manda "Linux; Android..." (ua.includes('linux') dá
// true) — sem essa checagem primeiro, detectOS() confundiria os dois com
// desktop de verdade e liberaria o download.
function isMobileOrTablet(request) {
  const ua = (request.headers.get('user-agent') || '').toLowerCase();

  if (/android|iphone|ipod|ipad|mobile|tablet/.test(ua)) return true;

  // Client Hint que navegadores Chromium (Chrome/Edge no Android, etc.)
  // já mandam por padrão, mesmo sem o site pedir via Accept-CH.
  // Vem como "?1" (true) ou "?0" (false).
  if (request.headers.get('sec-ch-ua-mobile') === '?1') return true;

  return false;
}

function mobileForbiddenResponse() {
  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Download disponível apenas no computador · Turbina</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0a0c10;
    --ink: #edeff4;
    --muted: #8891a7;
    --muted-2: #5c6478;
    --cyan: #4fd1ff;
    --violet: #8c6dff;
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
    background: rgba(79,209,255,0.08);
    border: 1px solid rgba(79,209,255,0.28);
    box-shadow: 0 0 40px rgba(79,209,255,0.15);
    color: var(--cyan);
  }
  .icon-ring svg { width: 30px; height: 30px; }
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
    margin: 0 0 30px;
  }
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
    <div class="icon-ring">
      ${MONITOR_ICON}
    </div>

    <span class="eyebrow"><span class="dot"></span> SÓ NO COMPUTADOR</span>

    <h1>Esse download é <span class="accent">só para desktop</span></h1>
    <p class="lede">Os scripts do Turbina rodam no terminal do computador — não têm como funcionar em celular ou tablet. Abra este link em um Windows, Mac ou Linux pra continuar.</p>

    <a class="btn" href="/#scripts">
      <svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M8 1v10M4 8l4 4 4-4M2 14h12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
      Voltar para o site
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

  // 1) mobile/tablet primeiro: bloqueia mesmo se o link foi colado direto,
  // copiado por long-press, aberto em nova aba, etc — não depende do JS
  // do site nem de como a pessoa chegou nesse link.
  if (isMobileOrTablet(request)) {
    return mobileForbiddenResponse();
  }

  // 2) só then checa se o OS desktop bate com o arquivo pedido
  const userAgent = request.headers.get('user-agent');
  const detected = detectOS(userAgent);

  if (detected !== requiredOS) {
    return forbiddenResponse(requiredOS, detected);
  }

  return next();
}
