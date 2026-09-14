# Instala Flutter SDK en el Windows Server (solo para builds; no es un servicio web).
# Ejecutar en PowerShell como Administrador en el servidor.
#
# Uso:
#   .\deploy\install-flutter-server.ps1
#   # cierra y abre PowerShell, luego:
#   flutter doctor
#   flutter config --enable-web

$ErrorActionPreference = "Stop"

$FlutterRoot = "D:\tools\flutter"
$ZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.2-stable.zip"
$ZipPath = "$env:TEMP\flutter_windows_stable.zip"
$ToolsDir = "D:\tools"

Write-Host "==> Destino: $FlutterRoot" -ForegroundColor Cyan
Write-Host "    (fuera de IIS / DjangoNewAPI — solo herramienta de build)"

New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

if (Test-Path "$FlutterRoot\bin\flutter.bat") {
    Write-Host "Flutter ya está en $FlutterRoot" -ForegroundColor Yellow
} else {
    if (Test-Path $FlutterRoot) {
        throw "Existe $FlutterRoot pero no parece un SDK válido. Bórralo o elige otra ruta."
    }

    Write-Host "==> Descargando Flutter 3.29.2 (estable)..." -ForegroundColor Cyan
    # Misma familia que el Dockerfile anterior (3.29.2)
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath

    Write-Host "==> Extrayendo en $ToolsDir ..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipPath -DestinationPath $ToolsDir -Force
    Remove-Item $ZipPath -Force

    if (-not (Test-Path "$FlutterRoot\bin\flutter.bat")) {
        throw "Extracción incompleta: no está flutter.bat"
    }
}

$Bin = "$FlutterRoot\bin"
$MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($MachinePath -notlike "*$Bin*") {
    Write-Host "==> Agregando $Bin al PATH del sistema" -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$MachinePath;$Bin", "Machine")
    $env:Path = "$env:Path;$Bin"
} else {
    Write-Host "PATH del sistema ya incluye Flutter" -ForegroundColor Yellow
    $env:Path = "$env:Path;$Bin"
}

Write-Host "==> flutter --version" -ForegroundColor Cyan
& "$Bin\flutter.bat" --version

Write-Host "==> Habilitar web" -ForegroundColor Cyan
& "$Bin\flutter.bat" config --enable-web

Write-Host @"

Listo.
1) Cierra esta ventana de PowerShell y abre una NUEVA (para cargar el PATH).
2) Verifica:  flutter doctor
3) En el repo:  .\deploy\update-frontend.ps1

No hace falta Android Studio ni emuladores para build web.
Chrome/Edge ayudan a flutter doctor pero no son obligatorios para 'flutter build web'.
"@ -ForegroundColor Green
