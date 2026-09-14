# Actualiza el frontend Mesa de Ayuda en el servidor.
# Uso (en el servidor, PowerShell):
#   cd "C:\Users\srvcaminitos\Documents\Gestor de Proyecto - Tickets"
#   .\deploy\update-frontend.ps1
#
# Requiere: git remote configurado + Docker Engine corriendo.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "==> git pull" -ForegroundColor Cyan
git pull

Write-Host "==> docker build" -ForegroundColor Cyan
docker build -t surgicorp/app_mesaayuda:latest .

Write-Host "==> recrear contenedor app_mesaayuda (:8010)" -ForegroundColor Cyan
docker stop app_mesaayuda 2>$null
docker rm app_mesaayuda 2>$null
docker run -d --name app_mesaayuda --restart unless-stopped -p 8010:80 surgicorp/app_mesaayuda:latest

Write-Host "==> verificar" -ForegroundColor Cyan
curl.exe -s -o $null -w "HTTP %{http_code}`n" http://localhost:8010/
Write-Host "Listo. Abre https://appsurgicorperu.com/app_mesaayuda/" -ForegroundColor Green
