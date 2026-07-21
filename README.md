# Turbina

Site estático (HTML/CSS/JS puro, sem build) apresentando os scripts de otimização Turbina para Windows, macOS e Linux.

## Estrutura

```
turbina-site/
├── index.html
├── assets/
│   ├── css/style.css
│   └── js/script.js
└── downloads/
    ├── turbina-windows.bat
    ├── turbina-mac.sh
    └── turbina-linux.sh
```

## Como publicar no GitHub Pages

1. Crie um repositório novo no GitHub (ex: `turbina`).
2. Suba todos os arquivos desta pasta para a raiz do repositório.
3. Vá em **Settings > Pages**.
4. Em "Source", selecione a branch `main` e a pasta `/ (root)`.
5. Salve. Em alguns minutos o site estará em `https://seu-usuario.github.io/turbina`.

Comandos via terminal:

```bash
git init
git add .
git commit -m "primeira versão do site Turbina"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/turbina.git
git push -u origin main
```

## Como publicar no Cloudflare Pages

1. Depois de subir o repositório no GitHub (passos acima), acesse [pages.cloudflare.com](https://pages.cloudflare.com).
2. Clique em **Create a project > Connect to Git**.
3. Escolha o repositório `turbina`.
4. Em "Build settings":
   - **Framework preset:** None
   - **Build command:** (deixe em branco)
   - **Build output directory:** `/`
5. Clique em **Save and Deploy**.

O Cloudflare vai te dar uma URL tipo `turbina.pages.dev`, e você pode depois apontar um domínio próprio nas configurações do projeto.

## Atualizando os scripts

Os arquivos baixáveis ficam em `downloads/`. Se você atualizar algum script, basta substituir o arquivo correspondente (mantendo o mesmo nome) e subir de novo (`git add . && git commit -m "atualiza script" && git push`).

## Licença

MIT — sinta-se livre para usar, modificar e distribuir.
