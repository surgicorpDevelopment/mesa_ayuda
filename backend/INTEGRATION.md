# Integración de `GestionProyectos` en DjangoNewAPI

Copia la carpeta `GestionProyectos/` a la raíz de `DjangoNewAPI` en el servidor
(`D:\DjangoNewAPI`).

## 1. Registrar la app

En `NewAPI/settings.py`, dentro de `INSTALLED_APPS`:

```python
'GestionProyectos.apps.GestionproyectosConfig',
```

## 2. Registrar rutas

En `ServidorCaminitos/urls.py`:

```python
from GestionProyectos.urls import register_gp_routes

# después de crear el DefaultRouter:
register_gp_routes(router)
```

## 3. Migrar, grupos y catálogo de sistemas

```powershell
cd D:\DjangoNewAPI
python manage.py migrate GestionProyectos
python manage.py setup_gp_groups
python manage.py seed_gp_sistemas
```

Las migraciones 0001–0006 vienen en el repo: usar `migrate` directo, **sin**
`makemigrations`, para no generar una migración duplicada en el servidor.

`0001_initial` depende de `ServidorCaminitos.0170_...` (igual que CajaChica),
porque `ExtendedUsers` no está en la migración `0001` de esa app. Si en el
servidor aparece una migración más nueva que `0170`, actualiza esa dependencia
al último leaf de `ServidorCaminitos` antes de migrar.

Después de esto hay que reciclar el application pool de IIS para que `wfastcgi`
recargue el código. No hace falta reiniciar Daphne: el módulo no usa WebSockets.

Luego puedes editar opciones en:

- Django Admin → **Sistemas / aplicaciones** (`GP_Sistema`)
- o `POST/PATCH /GP_Sistema/` (solo gestores)

Campos: `codigo` (único), `nombre`, `descripcion`, `activo`, `orden`.

## 4. Asignar roles (ejemplo shell)

```python
from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group

User = get_user_model()
u = User.objects.get(username='jeshua')
u.groups.add(Group.objects.get(name='gp_gestor_proyectos'))
```

Grupos: `gp_usuario`, `gp_desarrollador`, `gp_lider_area`, `gp_gestor_proyectos`.

**Tickets (helpdesk):** usuarios finales (`gp_usuario`) solo crean/ven los suyos.
Desarrolladores+ ven cola global de abiertos sin asignar (`POST /GP_Ticket/{id}/tomar/`).
**Proyectos y tareas:** solo desarrolladores, líderes y gestores.
**Comentarios e historial:** filtrados por la visibilidad de la entidad referida.

Las reglas de visibilidad viven en un solo sitio, `GestionProyectos/scoping.py`
(`visible_proyectos`, `visible_tickets`, `visible_tareas`); los ViewSets delegan ahí.

## 5. Endpoints

| Recurso | URL |
|---------|-----|
| Proyectos | `GET/POST /GP_Proyecto/` |
| Adjuntos de proyecto | `POST /GP_Proyecto/{id}/adjuntos/` (multipart, campo `archivo`) |
| Tickets | `GET/POST /GP_Ticket/` |
| Inbox | `GET /GP_Ticket/inbox/` (incluye `cola_sin_asignar`) |
| Tomar ticket | `POST /GP_Ticket/{id}/tomar/` |
| Adjuntos de ticket | `POST /GP_Ticket/{id}/adjuntos/` (multipart, campo `archivo`) |
| Tareas (Kanban) | `GET/POST /GP_Tarea/?proyecto=<id>` |
| Sistemas | `GET/POST /GP_Sistema/` · `GET /GP_Sistema/?activo=true` |
| Comentarios | `GET/POST /GP_Comentario/?tipo=ticket&ref_id=1` |
| Historial | `GET /GP_HistorialEstado/?tipo=ticket&ref_id=1` |
| Asignables | `GET /GP_Usuario/?q=<texto>` |
| Perfil y rol | `GET /GP_Usuario/me/` |
| Productividad | `GET /GP_Productividad/?desde=YYYY-MM-DD&hasta=YYYY-MM-DD` |

Auth: `Authorization: Bearer <access>` de `POST /api/token/`.

### `GET /GP_Usuario/me/`

El frontend depende de este endpoint para resolver el rol: `/api/token/` devuelve
el objeto `user` pero sin los grupos. Los campos `es_gestor`, `es_lider` y
`es_desarrollador` se calculan con los mismos helpers que autorizan las peticiones,
así que la UI nunca muestra acciones que la API vaya a rechazar con 403.

```json
{
  "id": 15,
  "username": "jeshua",
  "full_name": "Jeshua Cabanillas",
  "email": "jeshua@surgicorperu.com",
  "groups": ["gp_gestor_proyectos"],
  "area": "TI",
  "area_id": 15,
  "puesto": "Desarrollador Senior",
  "rol": "Gestor de proyectos",
  "is_staff": false,
  "es_gestor": true,
  "es_lider": true,
  "es_desarrollador": true
}
```

### Ejemplo alta de sistema

```http
POST /GP_Sistema/
Authorization: Bearer <token>
Content-Type: application/json

{
  "codigo": "portal_reps",
  "nombre": "Portal Representantes",
  "descripcion": "",
  "activo": true,
  "orden": 85
}
```

## 6. Requisitos del entorno a confirmar

- `django-filter` en `DEFAULT_FILTER_BACKENDS`, más `SearchFilter` y `OrderingFilter`:
  los ViewSets usan `filterset_fields`, `search_fields` y `ordering_fields`.
- Paginación global de DRF: el cliente lee `results` pero ignora `next`. Si hay
  paginación, revisar que el tamaño de página cubra las listas del MVP.
- `MEDIA_ROOT` con permiso de escritura para el usuario del application pool en
  `gp_tickets/` y `gp_proyectos/`, y `/media/` servido por IIS.
- Las URLs de adjuntos salen de `request.build_absolute_uri`: deben resolver a
  `https://appsurgicorperu.com/...` y no a `localhost`.
- `maxAllowedContentLength` de IIS (30 MB por defecto) para las capturas.
