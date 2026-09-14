# Gestor de Proyectos y Tickets (MVP)

Aplicación interna Surgicorp: **Flutter Web** + API **Django** (`GestionProyectos`) sobre `https://appsurgicorperu.com`.

## Qué incluye el MVP

- Login JWT (`POST /api/token/`)
- Tickets (crear, listar, filtrar, asignar, estados, comentarios)
- Cola helpdesk: desarrolladores ven tickets sin asignar de cualquier área (`tomar`)
- Proyectos (CRUD según rol; **ocultos** para `gp_usuario`)
- Roles: `gp_usuario`, `gp_desarrollador`, `gp_lider_area`, `gp_gestor_proyectos`
- Despliegue Docker + IIS en `/app_mesaayuda/` (puerto 8010)

## Estructura

| Carpeta | Contenido |
|---------|-----------|
| `lib/` | Cliente Flutter Web |
| `backend/GestionProyectos/` | App Django lista para copiar a DjangoNewAPI |
| `backend/local/` | Harness Django + Docker para probar GP_* en local (SQLite) |
| `deploy/` | nginx, snippet IIS, guía de despliegue |
| `docs/FASE2_POST_MVP.md` | Import Excel, tiempo, WhatsApp (después) |

## Desarrollo local (frontend)

```powershell
# Login real + tickets/proyectos MOCK (default en debug)
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:/tmp/chrome_dev"
```

Verás badge **MOCK** en el header. Los tickets/proyectos viven en memoria; el login sigue yendo a `appsurgicorperu.com`.

```powershell
# Forzar API real (cuando GP_* ya esté en el servidor)
flutter run -d chrome --dart-define=USE_MOCK=false --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:/tmp/chrome_dev"
```

API por defecto: `https://appsurgicorperu.com` (configurable con `--dart-define=API_BASE_URL=...`).

## API local (Docker, sin Postgres)

No hace falta instalar Postgres ni clonar DjangoNewAPI. El servidor usa SQL Server; este harness corre `GestionProyectos` con **SQLite** en Docker Desktop.

```powershell
# Docker Desktop encendido (solo el API; no reconstruye el frontend)
docker compose --profile local-api up --build api
```

API: `http://127.0.0.1:8000/` · Admin: `http://127.0.0.1:8000/admin/`

Credenciales (password `local123`):

| Usuario | Rol |
|---------|-----|
| `usuario` | `gp_usuario` (solo sus tickets) |
| `dev` | `gp_desarrollador` (cola / tomar) |
| `lider` | `gp_lider_area` |
| `gestor` | `gp_gestor_proyectos` |
| `admin` | superuser (Django admin) |

Flutter contra el API local (sin mock):

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=USE_MOCK=false --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:/tmp/chrome_dev"
```

`docker compose up` **sin** `--profile local-api` sigue levantando solo el frontend en el puerto 8010.

## Integrar backend

Ver [backend/INTEGRATION.md](backend/INTEGRATION.md).

## Desplegar frontend

Ver [deploy/DEPLOY.md](deploy/DEPLOY.md).

```powershell
docker compose up -d --build
```

URL: `https://appsurgicorperu.com/app_mesaayuda/`
