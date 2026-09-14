# Fase 2 (post-MVP)

Fuera del alcance actual. Implementar cuando el MVP esté estable en producción.

## 1. Import del Excel (~2079 filas)

- Exportar la hoja "Escritorio" a CSV.
- Script Django `manage.py import_gp_excel --file=ideas.csv`:
  - Mapear Área → `area_id` (`EU_Area`)
  - Estado Excel (`En Idea` / `Pendiente` / `En Proceso`) → `GP_Proyecto.estado` o `GP_Ticket` según tipo
  - Columnas D/E → `prioridad` / `impacto`
  - Responsable → `username` / FK user
- Dry-run primero; no borrar filas existentes.

## 2. Registro de tiempo

- Modelo `GP_TimeEntry`: user, tipo (ticket|proyecto), ref_id, minutos, nota, fecha.
- UI: botón "Registrar tiempo" en detalle.
- Reportes: horas por usuario / semana / área (vs avance de proyectos).

## 3. WhatsApp

- Reutilizar `WhatsApp_Integration` / Meta Cloud API ya en el backend.
- Flujo: usuario reporta → bot o formulario corto → crea `GP_Ticket` vía API.
- Notificar al asignado cuando cambia estado (plantilla Meta).
- No usar WhatsApp personal del desarrollador como canal oficial.
