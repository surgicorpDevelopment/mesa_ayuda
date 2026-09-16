# Actualiza el frontend Mesa de Ayuda en el servidor (rapido).
#
# Flujo: git pull -> flutter build (host) -> robocopy a deploy/webdist
#        -> imagen nginx -> recrear contenedor :8010
#
# Uso:
#   cd "C:\Users\srvcaminitos\Documents\Gestor de Proyecto - Tickets"
#   .\deploy\update-frontend.ps1
#
# Requiere: Flutter en PATH, git, Docker Engine.
# Este archivo es ASCII a proposito: PowerShell 5.1 del servidor
# no parsea bien UTF-8 sin BOM (el em-dash se vuelve un quote y rompe el script).

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Assert-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontro '$Name' en PATH. Instalalo o abre una sesion nueva tras instalarlo."
    }
}

Assert-Command git
Assert-Command flutter
Assert-Command docker

Write-Host "==> git pull" -ForegroundColor Cyan
git pull

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get

Write-Host "==> flutter build web (host)" -ForegroundColor Cyan
flutter build web --release --base-href /app_mesaayuda/ --pwa-strategy=none --no-wasm-dry-run

$webIndex = Join-Path $RepoRoot "build\web\index.html"
$webAssets = Join-Path $RepoRoot "build\web\assets\FontManifest.json"
if (-not (Test-Path $webIndex)) {
    throw "No existe build\web\index.html - el build de Flutter fallo."
}
if (-not (Test-Path $webAssets)) {
    throw "No existe build\web\assets\FontManifest.json - Flutter no empaqueto assets."
}

$dist = Join-Path $RepoRoot "deploy\webdist"
Write-Host "==> copiar build\web a deploy\webdist (archivos reales)" -ForegroundColor Cyan
if (Test-Path $dist) {
    Remove-Item $dist -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dist | Out-Null
& robocopy (Join-Path $RepoRoot "build\web") $dist /E /COPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS | Out-Null
# robocopy: 0-7 ok, >=8 error. PS 5.1 no tira por exit code nativo.
if ($LASTEXITCODE -ge 8) {
    throw "robocopy fallo con codigo $LASTEXITCODE"
}

$distAssets = Join-Path $dist "assets\FontManifest.json"
if (-not (Test-Path $distAssets)) {
    throw "deploy\webdist no tiene assets\FontManifest.json"
}

Write-Host "==> docker build (nginx, segundos)" -ForegroundColor Cyan
docker build -f Dockerfile.nginx -t surgicorp/app_mesaayuda:latest .

Write-Host "==> recrear contenedor app_mesaayuda (:8010)" -ForegroundColor Cyan
docker stop app_mesaayuda 2>$null | Out-Null
docker rm app_mesaayuda 2>$null | Out-Null
$id = docker run -d --name app_mesaayuda --restart unless-stopped -p 8010:80 surgicorp/app_mesaayuda:latest
Write-Host "container $id"

Write-Host "==> verificar" -ForegroundColor Cyan
Start-Sleep -Seconds 2
docker exec app_mesaayuda test -f /usr/share/nginx/html/assets/FontManifest.json
if ($LASTEXITCODE -ne 0) {
    throw "La imagen no incluye /usr/share/nginx/html/assets/FontManifest.json"
}

# En Windows, -o $null no funciona: usar NUL y curl.exe (no el alias de PowerShell)
$code = & curl.exe -s -o NUL -w "%{http_code}" http://localhost:8010/
Write-Host "HTTP index $code"
if ($code -ne "200") {
    throw "El contenedor no respondio 200 (codigo '$code')."
}

# curl -sI returns string[]; -notmatch on arrays filters lines (truthy) and
# falsely fails even when Content-Type is application/json. Join first.
$assetHeaders = (& curl.exe -sI http://localhost:8010/assets/FontManifest.json) -join "`n"
Write-Host "FontManifest headers:`n$assetHeaders"
if ($assetHeaders -notmatch "(?i)Content-Type:\s*(application/json|text/plain)") {
    throw "FontManifest.json no se sirvio como archivo (IIS/nginx devolvio HTML)."
}

Write-Host "Listo. Abre https://appsurgicorperu.com/app_mesaayuda/" -ForegroundColor Green
Write-Host "Si ves pantalla en blanco: Ctrl+Shift+R o borrar datos del sitio (service worker viejo)." -ForegroundColor Yellow
