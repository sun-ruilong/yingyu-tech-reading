$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$sourceDir = Get-ChildItem -LiteralPath $root -Directory |
  Where-Object {
    $_.Name -like '*codex*' -and
    (Get-ChildItem -LiteralPath $_.FullName -Filter '*.html' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
  } |
  Select-Object -First 1 -ExpandProperty FullName
$stagingRoot = Join-Path $PSScriptRoot 'staging'
$siteDir = Join-Path $stagingRoot 'yingyu'
$codexDir = Join-Path $siteDir 'codex'
$archive = Join-Path $PSScriptRoot 'yingyu-static.tar.gz'
$sshKey = Join-Path $env:USERPROFILE '.ssh\yingyu_tencent_ed25519'
$remote = 'root@111.230.71.5'
$remoteRoot = '/www/wwwroot/yingyu'
$publicUrl = 'https://en.nextlong.cn/'

if (-not $sourceDir -or -not (Test-Path -LiteralPath $sourceDir)) {
  throw "Source directory not found: $sourceDir"
}
if (-not (Test-Path -LiteralPath $sshKey)) {
  throw "SSH key not found: $sshKey"
}

if (Test-Path -LiteralPath $stagingRoot) {
  Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $codexDir | Out-Null

Get-ChildItem -LiteralPath $sourceDir -Filter '*.html' |
  Copy-Item -Destination $codexDir -Force
if (Test-Path -LiteralPath (Join-Path $sourceDir '_audio')) {
  Copy-Item -LiteralPath (Join-Path $sourceDir '_audio') -Destination $codexDir -Recurse -Force
}

$articleFiles = @(Get-ChildItem -LiteralPath $codexDir -Filter '*.html' | Sort-Object Name)
$articles = for ($i = 0; $i -lt $articleFiles.Count; $i++) {
  $file = $articleFiles[$i]
  $href = 'codex/' + [System.Uri]::EscapeDataString($file.Name)
  $title = [System.Net.WebUtility]::HtmlEncode($file.BaseName)
  $date = 'Reading'
  if ($file.BaseName -match '^(\d{4}-\d{2}-\d{2})') {
    $date = $Matches[1]
  }
  $num = ($i + 1).ToString('00')
  @"
        <li class="article-card">
          <a href="$href">
            <span class="article-index">$num</span>
            <span class="article-main">
              <span class="article-title">$title</span>
              <span class="article-meta">$date &middot; Codex Reading</span>
            </span>
            <span class="article-arrow" aria-hidden="true">-&gt;</span>
          </a>
        </li>
"@
}

$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$index = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>&#25216;&#26415;&#33521;&#25991;&#31934;&#35835;</title>
  <style>
    :root {
      --ink: #151515;
      --text: #232323;
      --muted: #69716d;
      --paper: #fbfaf6;
      --wash: #f1f3ed;
      --surface: #ffffff;
      --line: #dfe4da;
      --line-strong: #c9d1c4;
      --accent: #3f7b63;
      --accent-deep: #245b47;
      --shadow: 0 18px 48px rgba(28, 33, 29, 0.10);
      --shadow-soft: 0 8px 24px rgba(28, 33, 29, 0.07);
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      background: linear-gradient(180deg, #f4f6f0 0%, #fbfaf6 340px, #f4f6f0 100%);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.7;
      overflow-x: hidden;
    }
    body::before {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      background-image: linear-gradient(rgba(21,21,21,0.025) 1px, transparent 1px);
      background-size: 100% 32px;
      mask-image: linear-gradient(180deg, rgba(0,0,0,0.35), transparent 55%);
    }
    main {
      position: relative;
      width: 100%;
      max-width: 880px;
      margin: 0 auto;
      padding: 44px 20px 82px;
    }
    .hero {
      position: relative;
      border: 1px solid var(--line-strong);
      border-radius: 8px;
      background: linear-gradient(135deg, rgba(255,255,255,0.96), rgba(246,248,242,0.95));
      box-shadow: var(--shadow);
      padding: 34px 34px 32px;
      margin-bottom: 20px;
      overflow: hidden;
      max-width: 100%;
    }
    .hero::after {
      content: "READ";
      position: absolute;
      right: 24px;
      bottom: -18px;
      color: rgba(63, 123, 99, 0.08);
      font-size: 88px;
      font-weight: 900;
      line-height: 1;
      letter-spacing: 0.03em;
      pointer-events: none;
    }
    .eyebrow {
      position: relative;
      z-index: 1;
      margin-bottom: 10px;
      color: var(--accent-deep);
      font-size: 12px;
      font-weight: 800;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }
    h1 {
      position: relative;
      z-index: 1;
      margin: 0;
      color: var(--ink);
      font-size: 34px;
      line-height: 1.22;
      letter-spacing: 0;
      overflow-wrap: anywhere;
    }
    p {
      position: relative;
      z-index: 1;
      max-width: 580px;
      color: var(--muted);
      margin: 12px 0 0;
      font-size: 16px;
    }
    ul {
      list-style: none;
      padding: 0;
      margin: 0;
      display: grid;
      gap: 12px;
    }
    .article-card a {
      display: grid;
      grid-template-columns: 54px minmax(0, 1fr) auto;
      gap: 14px;
      align-items: center;
      min-height: 84px;
      padding: 16px 18px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: rgba(255,255,255,0.92);
      color: var(--ink);
      text-decoration: none;
      overflow-wrap: anywhere;
      box-shadow: var(--shadow-soft);
      transition: transform 0.16s ease, border-color 0.16s ease, box-shadow 0.16s ease, background 0.16s ease;
    }
    .article-card a:hover {
      transform: translateY(-2px);
      border-color: var(--accent);
      background: #fff;
      box-shadow: 0 16px 34px rgba(28, 33, 29, 0.12);
    }
    .article-index {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 42px;
      height: 42px;
      border-radius: 999px;
      background: #edf5ee;
      color: var(--accent-deep);
      font-size: 13px;
      font-weight: 900;
    }
    .article-main {
      display: grid;
      gap: 4px;
      min-width: 0;
    }
    .article-title {
      color: var(--ink);
      font-size: 18px;
      font-weight: 850;
      line-height: 1.35;
    }
    .article-meta {
      color: var(--muted);
      font-size: 13px;
    }
    .article-arrow {
      color: var(--accent-deep);
      font-weight: 900;
    }
    .meta {
      margin-top: 18px;
      font-size: 13px;
      color: #8a918d;
    }
    @media (max-width: 560px) {
      main {
        padding: 22px 14px 68px;
      }
      .hero {
        padding: 26px 18px 24px;
      }
      .hero::after {
        display: none;
      }
      h1 {
        font-size: 28px;
      }
      .article-card a {
        grid-template-columns: 42px minmax(0, 1fr);
        padding: 14px;
      }
      .article-index {
        width: 34px;
        height: 34px;
      }
      .article-arrow {
        display: none;
      }
    }
  </style>
</head>
<body>
  <main>
    <section class="hero">
      <div class="eyebrow">Codex Reading</div>
      <h1>&#25216;&#26415;&#33521;&#25991;&#31934;&#35835;</h1>
      <p>Codex &#23448;&#26041;&#25991;&#26723;&#31934;&#35835;&#23398;&#20064;&#39029;&#12290;</p>
    </section>
    <ul>
$($articles -join "`n")
    </ul>
    <div class="meta">Updated: $generatedAt</div>
  </main>
</body>
</html>
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText((Join-Path $siteDir 'index.html'), $index, $utf8NoBom)

if (Test-Path -LiteralPath $archive) {
  Remove-Item -LiteralPath $archive -Force
}
Push-Location $stagingRoot
try {
  tar -czf $archive yingyu
}
finally {
  Pop-Location
}

ssh -i $sshKey $remote "mkdir -p '$remoteRoot'"
scp -i $sshKey $archive "${remote}:/tmp/yingyu-static.tar.gz"
ssh -i $sshKey $remote "set -e; rm -rf '${remoteRoot}.new'; mkdir -p '${remoteRoot}.new'; tar -xzf /tmp/yingyu-static.tar.gz -C '${remoteRoot}.new' --strip-components=1; if [ -d '$remoteRoot' ]; then rm -rf '${remoteRoot}.bak'; mv '$remoteRoot' '${remoteRoot}.bak'; fi; mv '${remoteRoot}.new' '$remoteRoot'; chown -R www:www '$remoteRoot' 2>/dev/null || true; chmod -R a+rX '$remoteRoot'; nginx -t && nginx -s reload"

Write-Host "Deployed to $publicUrl"
