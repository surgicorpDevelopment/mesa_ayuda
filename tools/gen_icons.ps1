# Genera el icono de Mesa de Ayuda: glifo de ticket en teal sobre fondo
# transparente (mismo estilo que los demas favicons del portal).
#
# Claves para que se lea a 16px:
#   - el glifo ES la silueta, no hay cuadro de fondo que le robe area
#   - las muescas se recortan de verdad (Region.Exclude), no se pintan encima
#   - el detalle interior solo aparece cuando hay pixeles suficientes
#
# Uso:
#   . .\tools\gen_icons.ps1
#   Save-IconSet -WebDir ".\web"
#   New-PreviewSheet -OutPath "$env:TEMP\ticket-glyph.png"

Add-Type -AssemblyName System.Drawing

$script:Teal = [System.Drawing.Color]::FromArgb(255, 15, 118, 110)

function Add-RoundRect($path, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  if ($r -le 0.6) {
    $path.AddRectangle((New-Object System.Drawing.RectangleF $x, $y, $w, $h))
    return
  }
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
}

function New-RoundRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  Add-RoundRect $p $x $y $w $h $r
  return $p
}

<#
  Dibuja el ticket.
  -Solid: fondo teal y glifo blanco (para iconos maskable de PWA, que se recortan).
  Por defecto: glifo teal sobre transparente.
#>
function New-TicketIcon {
  param(
    [int]$Size,
    [switch]$Solid
  )

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bmp.SetResolution(72, 72)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  if ($Solid) {
    $g.Clear($script:Teal)
    $glyphColor = [System.Drawing.Color]::White
    $pad = $Size * 0.20
  } else {
    $g.Clear([System.Drawing.Color]::Transparent)
    $glyphColor = $script:Teal
    $pad = $Size * 0.045
  }

  $w = $Size - 2 * $pad
  $h = $w * 0.72
  $x = $pad
  $y = ($Size - $h) / 2.0
  $r = [Math]::Max(1.2, $Size * 0.10)
  # Mordida discreta: si es profunda el ticket se lee como reloj de arena.
  $notch = $h * 0.15

  $body = New-RoundRectPath $x $y $w $h $r
  $region = New-Object System.Drawing.Region $body

  # Muescas laterales: el rasgo que identifica al ticket. Se recortan.
  $midY = $y + $h / 2.0
  foreach ($cx in @(($x), ($x + $w))) {
    $hole = New-Object System.Drawing.Drawing2D.GraphicsPath
    $hole.AddEllipse(($cx - $notch), ($midY - $notch), ($notch * 2), ($notch * 2))
    $region.Exclude($hole)
    $hole.Dispose()
  }

  # Perforacion + texto: solo en tamanos grandes. A 16-48px el detalle
  # se convierte en ruido y el ticket deja de leerse.
  if ($Size -ge 96) {
    $lineW = $Size * 0.035
    $stubX = $x + $w * 0.68

    $dashH = $h * 0.10
    $dashGap = $dashH * 0.85
    $yy = $y + $h * 0.16
    while ($yy -lt ($y + $h * 0.84)) {
      $seg = New-RoundRectPath ($stubX - $lineW / 2.0) $yy $lineW $dashH ($lineW / 2.0)
      $region.Exclude($seg)
      $seg.Dispose()
      $yy += $dashH + $dashGap
    }

    foreach ($p in @(@(0.36, 0.32), @(0.56, 0.22))) {
      $ly = $y + $h * $p[0]
      $lx = $x + $w * 0.16
      $lw = $w * $p[1]
      $bar = New-RoundRectPath $lx $ly $lw $lineW ($lineW / 2.0)
      $region.Exclude($bar)
      $bar.Dispose()
    }
  }

  $brush = New-Object System.Drawing.SolidBrush $glyphColor
  $g.FillRegion($brush, $region)

  $brush.Dispose(); $region.Dispose(); $body.Dispose(); $g.Dispose()
  return $bmp
}

function Save-IconSet {
  param([string]$WebDir)

  $iconsDir = Join-Path $WebDir "icons"
  if (-not (Test-Path $iconsDir)) { New-Item -ItemType Directory -Path $iconsDir | Out-Null }

  $targets = @(
    @{ Size = 32;  Path = (Join-Path $WebDir "favicon.png") },
    @{ Size = 48;  Path = (Join-Path $WebDir "favicon-48.png") },
    @{ Size = 192; Path = (Join-Path $iconsDir "Icon-192.png") },
    @{ Size = 512; Path = (Join-Path $iconsDir "Icon-512.png") }
  )
  foreach ($t in $targets) {
    $b = New-TicketIcon -Size $t.Size
    $b.Save($t.Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
    Write-Output "$($t.Path) ($($t.Size)px)"
  }

  # Los maskable se recortan a circulo: necesitan fondo solido.
  foreach ($s in @(192, 512)) {
    $b = New-TicketIcon -Size $s -Solid
    $out = Join-Path $iconsDir "Icon-maskable-$s.png"
    $b.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
    Write-Output "$out ($s px, maskable)"
  }
}

function New-PreviewSheet {
  param([string]$OutPath)

  $sizes = @(16, 24, 32, 48, 128)
  $margin = 24
  $gap = 30
  $rowH = 128 + 34
  $sheetW = [int]($margin * 2 + ($sizes | Measure-Object -Sum).Sum + $gap * $sizes.Count)
  $sheetH = [int]($margin * 2 + $rowH * 2)

  $sheet = New-Object System.Drawing.Bitmap ([int]$sheetW), ([int]$sheetH)
  $g = [System.Drawing.Graphics]::FromImage($sheet)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::White)

  $small = New-Object System.Drawing.Font "Segoe UI", 10
  $bold = New-Object System.Drawing.Font "Segoe UI", 12, ([System.Drawing.FontStyle]::Bold)
  $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 100, 116, 139))
  $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 15, 23, 42))
  $tabBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 241, 245, 249))

  # fila 1: sobre blanco (pestana activa) / fila 2: sobre gris (pestana inactiva)
  $rowY = $margin
  foreach ($bg in @('blanco', 'gris')) {
    if ($bg -eq 'gris') {
      $g.FillRectangle($tabBg, 0, ($rowY - 8), $sheetW, ($rowH - 10))
    }
    $g.DrawString("fondo $bg", $bold, $ink, [float]$margin, [float]($rowY + 132))
    $x = $margin
    foreach ($s in $sizes) {
      $b = New-TicketIcon -Size $s
      $yy = $rowY + (128 - $s) / 2
      $g.DrawImage($b, [int]$x, [int]$yy, [int]$s, [int]$s)
      $b.Dispose()
      $g.DrawString("${s}px", $small, $muted, [float]$x, [float]($rowY + 112))
      $x += $s + $gap
    }
    $rowY += $rowH
  }

  $small.Dispose(); $bold.Dispose(); $muted.Dispose(); $ink.Dispose(); $tabBg.Dispose(); $g.Dispose()
  $sheet.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $sheet.Dispose()
  Write-Output "Preview: $OutPath"
}
