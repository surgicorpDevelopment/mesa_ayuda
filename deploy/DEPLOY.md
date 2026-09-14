# Despliegue — Mesa de Ayuda (Gestor de Proyectos / Tickets)

URL objetivo: `https://appsurgicorperu.com/app_mesaayuda/`

## Prerrequisitos

1. Backend `GestionProyectos` integrado en DjangoNewAPI (ver [backend/INTEGRATION.md](../backend/INTEGRATION.md)).
2. Docker Desktop / Engine en el Windows Server.
3. Puerto **8010** libre en el host.

## 1. Build y run del contenedor

En la máquina de desarrollo o en el servidor (carpeta del repo):

```powershell
docker build -t surgicorp/app_mesaayuda:latest .
docker run -d --name app_mesaayuda --restart unless-stopped -p 8010:80 surgicorp/app_mesaayuda:latest
```

Verificar:

```powershell
curl http://localhost:8010/
```

## 2. Regla IIS

Agregar en `web.config` (junto a las otras `App_*`), usando el fragmento de [iis-rule-snippet.xml](iis-rule-snippet.xml):

```
Match: ^app_mesaayuda/(.*)
Rewrite: http://localhost:8010/{R:1}
```

Reiniciar el sitio IIS o hacer `iisreset` solo si es necesario.

> La documentación del servidor marca como regla de oro no tocar `web.config` sin
> indicación explícita: pedir el visto bueno antes de aplicar este paso.

## 3. Smoke test

1. Abrir `https://appsurgicorperu.com/app_mesaayuda/`
2. Login con usuario real (`jeshua` + JWT); el badge **MOCK** no debe aparecer
3. Crear un ticket con captura y verificar que el adjunto quede en `/media/gp_tickets/`
4. Como gestor/dev: tomar de la cola, asignar y cambiar estado
5. Crear un proyecto, agregar una tarea y moverla en el Kanban
6. Revisar que Reportes muestre el evento recién generado
7. Confirmar que CSS/JS cargan (si la pantalla queda blanca → falta `--base-href /app_mesaayuda/`)

Con el token de un `gp_usuario` y `curl` (la UI oculta las opciones y daría un falso verde):

```powershell
# 403
curl -X POST https://appsurgicorperu.com/GP_Tarea/ -H "Authorization: Bearer $t" -H "Content-Type: application/json" -d '{"titulo":"x","proyecto":1}'
# listas vacías
curl "https://appsurgicorperu.com/GP_Comentario/?tipo=ticket&ref_id=1" -H "Authorization: Bearer $t"
curl "https://appsurgicorperu.com/GP_HistorialEstado/?tipo=proyecto&ref_id=1" -H "Authorization: Bearer $t"
```

## 4. Desarrollo local (sin Docker)

```powershell
flutter run -d chrome --web-port 5173
# API apunta a https://appsurgicorperu.com (ApiConfig)
# Asegurar hosts: 192.168.2.134 appsurgicorperu.com
```

Build de prueba con subpath:

```powershell
flutter build web --release --base-href /app_mesaayuda/
```

## 5. Actualizar versión (flujo normal — rápido)

Repo: https://github.com/surgicorpDevelopment/mesa_ayuda

**Requisito en el servidor:** Flutter SDK (ver `deploy/install-flutter-server.ps1`).

**En tu PC (después de cambios):**
```powershell
git add .
git commit -m "mensaje"
git push
```

**En el servidor:**
```powershell
cd "C:\Users\srvcaminitos\Documents\Gestor de Proyecto - Tickets"
.\deploy\update-frontend.ps1
```

Eso hace: `git pull` → `flutter build web` (host) → imagen **nginx** (`Dockerfile.nginx`) → recrea `:8010`.  
IIS no se toca. Suele tardar minutos, no horas.

### Instalar Flutter en el servidor (una sola vez)

PowerShell **como Administrador**:
```powershell
cd "C:\Users\srvcaminitos\Documents\Gestor de Proyecto - Tickets"
.\deploy\install-flutter-server.ps1
```
Instala en `D:\tools\flutter` (fuera de IIS). Cierra y abre PowerShell, luego `flutter doctor`.

### Fallback lento (compilar dentro de Docker)

```powershell
docker build -f Dockerfile -t surgicorp/app_mesaayuda:latest .
```
Solo si no hay Flutter en el host; puede tardar mucho.

## 6. Rollback

```powershell
docker stop app_mesaayuda
```

Quitar la regla `App_MesaAyuda` del `web.config`. En el backend, sacar
`register_gp_routes(router)` de `ServidorCaminitos/urls.py` y la app de
`INSTALLED_APPS`, y reciclar el application pool. Las tablas `GP_*` quedan
huérfanas sin afectar al resto del sistema.
