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
  linux: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 280">
    <defs>
      <radialGradient id="corpoGrad" cx="50%" cy="30%" r="70%">
        <stop offset="0%" stop-color="#444444" />
        <stop offset="40%" stop-color="#111111" />
        <stop offset="100%" stop-color="#000000" />
      </radialGradient>
      <linearGradient id="brilhoCabeca" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.6" />
        <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0" />
      </linearGradient>
      <radialGradient id="barrigaGrad" cx="50%" cy="50%" r="50%">
        <stop offset="70%" stop-color="#FFFFFF" />
        <stop offset="95%" stop-color="#EAEAEA" />
        <stop offset="100%" stop-color="#D0D0D0" />
      </radialGradient>
      <linearGradient id="amareloGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFF066" />
        <stop offset="40%" stop-color="#F2B705" />
        <stop offset="100%" stop-color="#C48200" />
      </linearGradient>
      <filter id="sombra">
        <feGaussianBlur stdDeviation="3" result="blur" />
        <feColorMatrix type="matrix" values="0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.3 0"/>
      </filter>
    </defs>
    <path d="M 125 15 C 70 15 65 80 65 110 C 65 130 50 155 40 185 C 25 215 45 255 125 255 C 205 255 225 215 210 185 C 200 155 185 130 185 110 C 185 80 180 15 125 15 Z" fill="url(#corpoGrad)" />
    <ellipse cx="125" cy="30" rx="35" ry="12" fill="url(#brilhoCabeca)" />
    <path d="M 68 130 C 40 150 30 190 45 215 C 55 225 65 210 65 190 C 65 170 73 145 78 135 Z" fill="#050505" />
    <ellipse cx="50" cy="180" rx="6" ry="20" fill="#FFFFFF" opacity="0.1" transform="rotate(-20 50 180)" />
    <path d="M 182 130 C 210 150 220 190 205 215 C 195 225 185 210 185 190 C 185 170 177 145 172 135 Z" fill="#050505" />
    <ellipse cx="200" cy="180" rx="6" ry="20" fill="#FFFFFF" opacity="0.1" transform="rotate(20 200 180)" />
    <ellipse cx="125" cy="115" rx="55" ry="15" fill="#000000" filter="url(#sombra)" />
    <path d="M 125 105 C 80 105 70 140 70 180 C 70 225 90 250 125 250 C 160 250 180 225 180 180 C 180 140 170 105 125 105 Z" fill="url(#barrigaGrad)" />
    <path d="M 125 120 L 125 230" stroke="#EAEAEA" stroke-width="3" opacity="0.7" />
    <ellipse cx="102" cy="70" rx="15" ry="22" fill="#FFFFFF" />
    <ellipse cx="104" cy="74" rx="7" ry="10" fill="#000000" />
    <circle cx="102" cy="70" r="3" fill="#FFFFFF" />
    <ellipse cx="148" cy="70" rx="15" ry="22" fill="#FFFFFF" />
    <ellipse cx="146" cy="74" rx="7" ry="10" fill="#000000" />
    <circle cx="144" cy="70" r="3" fill="#FFFFFF" />
    <path d="M 90 85 C 90 70 160 70 160 85 C 160 100 155 115 125 115 C 95 115 90 100 90 85 Z" fill="url(#amareloGrad)" />
    <path d="M 92 83 Q 125 98 158 83" stroke="#A36200" stroke-width="2" fill="none" />
    <ellipse cx="125" cy="80" rx="25" ry="6" fill="#FFFFFF" opacity="0.3" />
    <path d="M 40 230 C 15 225 5 255 25 268 C 45 280 85 270 95 250 C 75 240 55 235 40 230 Z" fill="url(#amareloGrad)" />
    <path d="M 210 230 C 235 225 245 255 225 268 C 205 280 165 270 155 250 C 175 240 195 235 210 230 Z" fill="url(#amareloGrad)" />
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
  .icon-ring.icon-linux svg { width: 34px; height: 38px; }

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
