// Cloudflare Pages Function
// Caminho no projeto: /functions/downloads/[[path]].js
// (a pasta "functions" fica na RAIZ do repositório, ao lado da pasta
// que você publica como site — NÃO dentro dela)
//
// O que isso faz:
// Intercepta qualquer pedido para /downloads/* e só entrega o arquivo
// se o User-Agent do pedido corresponder ao sistema operacional daquele
// arquivo. Ex: /downloads/turbina-mac.sh só é servido se o User-Agent
// indicar macOS; em qualquer outro caso, retorna 403.
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

function detectOS(userAgent) {
  const ua = (userAgent || '').toLowerCase();
  if (ua.includes('mac')) return 'mac';
  if (ua.includes('win')) return 'win';
  if (ua.includes('linux') || ua.includes('x11') || ua.includes('ubuntu')) return 'linux';
  return null;
}

function forbiddenResponse(requiredOS) {
  const label = OS_LABEL[requiredOS] || 'outro sistema';
  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Download não disponível para o seu sistema</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: system-ui, sans-serif; background: #0a0c10; color: #edeff4; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 24px; text-align: center; }
  .box { max-width: 420px; }
  h1 { font-size: 1.3rem; margin-bottom: 12px; }
  p { color: #8891a7; line-height: 1.6; }
  a { color: #4fd1ff; text-decoration: none; font-weight: 600; }
</style>
</head>
<body>
  <div class="box">
    <h1>Este script é para ${label}</h1>
    <p>O arquivo que você tentou baixar foi feito para outro sistema operacional e não é compatível com o seu.</p>
    <p><a href="/#scripts">Voltar e baixar o script certo para o seu sistema</a></p>
  </div>
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
    return forbiddenResponse(requiredOS);
  }

  return next();
}
