from PIL import Image, ImageDraw
import io, base64, pathlib

out = pathlib.Path(__file__).resolve().parents[1] / 'lib' / 'services' / 'mock_attachment_assets.dart'
specs = [
    ('PdaScan', (30, 58, 95), (255, 255, 255), 'PDA · QR no lee'),
    ('QrBlank', (15, 23, 42), (249, 115, 22), 'Pantalla en blanco'),
    ('Almacen', (37, 99, 235), (255, 255, 255), 'Almacen principal'),
]
lines = [
    '// Capturas mock (PNG data URL) para semillas de tickets.',
    '// Generado para desarrollo local; no usar en produccion.',
    '',
]
for name, bg, fg, label in specs:
    im = Image.new('RGB', (320, 240), bg)
    d = ImageDraw.Draw(im)
    d.rectangle([16, 16, 304, 224], outline=fg, width=3)
    d.rectangle([40, 60, 280, 180], fill=(bg[0] // 2, bg[1] // 2, bg[2] // 2))
    d.text((56, 108), label, fill=fg)
    buf = io.BytesIO()
    im.save(buf, 'PNG')
    b64 = base64.b64encode(buf.getvalue()).decode()
    size = len(buf.getvalue())
    lines.append(f"const String mockImg{name} = 'data:image/png;base64,{b64}';")
    lines.append(f'const int mockImg{name}Bytes = {size};')
    lines.append('')

out.write_text('\n'.join(lines), encoding='utf-8')
print('wrote', out, 'bytes', out.stat().st_size)
