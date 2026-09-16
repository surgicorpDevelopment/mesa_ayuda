# Actualiza el frontend Mesa de Ayuda en el servidor (rapido).
#
# Flujo: git pull -> flutter build (host) -> imagen nginx -> recrear contenedor :8010
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
flutter build web --release --base-href /app_mesaayuda/

if (-not (Test-Path "build\web\index.html")) {
    throw "No existe build\web\index.html - el build de Flutter fallo."
}

Write-Host "==> docker build (nginx, segundos)" -ForegroundColor Cyan
docker build -f Dockerfile.nginx -t surgicorp/app_mesaayuda:latest .

Write-Host "==> recrear contenedor app_mesaayuda (:8010)" -ForegroundColor Cyan
docker stop app_mesaayuda 2>$null | Out-Null
docker rm app_mesaayuda 2>$null | Out-Null
$id = docker run -d --name app_mesaayuda --restart unless-stopped -p 8010:80 surgicorp/app_mesaayuda:latest
Write-Host "container $id"

Write-Host "==> verificar" -ForegroundColor Cyan
Start-Sleep -Seconds 1
# En Windows, -o $null no funciona: usar NUL y curl.exe (no el alias de PowerShell)
$code = & curl.exe -s -o NUL -w "%{http_code}" http://localhost:8010/
Write-Host "HTTP $code"
if ($code -ne "200") {
    throw "El contenedor no respondio 200 (codigo '$code')."
}
Write-Host "Listo. Abre https://appsurgicorperu.com/app_mesaayuda/" -ForegroundColor Green
