# Void Sentinel — Plan de trabajo (vivo)

> Fuente de verdad del trabajo. Marca `[x]` lo hecho. No hay que releer los `.docx`
> de Downloads (`FLUJO_TRABAJO_*` y `FLUJO_POSTBETA_*`); este archivo los reemplaza
> como guía operativa. Las fechas de esos documentos eran estimaciones a la baja:
> el proyecto va **meses por delante** del cronograma original.

## Decisiones tomadas
- **Gacha: APARCADO.** No se implementa cartas/módulos por ahora (alta complejidad y
  mantenimiento). Posible v3.0 si el juego funciona. Monetización vía IAP + Ads.
- **Plataforma objetivo:** Android (APK exportable, vertical 720×1280). Build actual: `v0.3`.

## Estado actual (hecho ✅)
Núcleo jugable completo: oleadas/ascensiones, escalado de enemigos centralizado,
balance multiplicativo (daño/vida ×1.03^nivel), sistema de interés, 23 mejoras
(Workshop), 6 tipos de enemigo, Forja con 8 habilidades, Commander, economía
permanente (ecos/fragmentos), logros + estadísticas del Perfil, formato de números
grandes, juice (partículas + screen shake), menú de pausa, **reanudar partida
(checkpoint)**, UI escalada para móvil (notch + fuentes), modo prueba para testear
endgame.

---

## BLOQUE A — Cerrar la Beta v1.0
Lo que falta para una beta "viva" y completa.

- [~] **A1 · Audio (prioridad #1)** — infraestructura lista; faltan los archivos.
  - [x] Autoload `AudioManager` (carga perezosa, pool de canales, volumen, loop)
  - [x] SFX enganchados: disparo, muerte, crítico, daño al Nexus, compra, game over
  - [x] Música cableada: `combate` (en partida) y `menu` (en Home)
  - [ ] **Conseguir y soltar los archivos** en `res://audio/sfx/` y `/music/` (ver `audio/README.md`)
- [ ] **A2 · Tutorial básico** (3 pantallas o tooltips de primera partida)
- [ ] **A3 · Arte** — reemplazar placeholders clave (incremental, no bloqueante)
- [ ] **A4 · Juice extra (opcional)** — hit-pause al crítico/muerte, más partículas
- [ ] **A5 · Testing de beta** — jugar largo, balance, 0 crashes; regenerar APK
- [x] **A2 hecho** — Tutorial de primera partida (3 pantallas: Nexus / energía-mejoras-dron /
  ascensiones-Commander). `scripts/ui/TutorialOverlay.gd`, enganchado en `mundo.gd`. Solo en
  partidas nuevas, pausa el juego y persiste flag en `user://tutorial.save`. (commit 8e5cdc4)
- [ ] **A6 · Arreglar Panel de Mejoras** (BUG pendiente — para retomar)
  - Síntomas al intentar "arranca colapsado + altura ajustada al contenido":
    1. Colapsado aparecía **flotando en medio**, no abajo.
    2. Al cambiar a la pestaña **Defensa el panel desaparecía**.
    3. El **scroll de Ataque no funciona** (ya pasaba antes).
  - Causa identificada: `_reposicionar()` lee la altura del grid con
    `get_combined_minimum_size()` pero los contenedores internos (`Contenido`,
    `ScrollContainer`) tienen **offsets fijos en el `.tscn`** que chocan con el ajuste
    dinámico; además el minimum-size del grid recién hecho visible no está listo en el
    mismo frame (hace falta `await` o `call_deferred`). El cambio se **revirtió**; el
    panel sigue como estaba (expandido, altura fija 500px, con hueco negro).
  - Decisión pendiente: probablemente toque editar el `.tscn` (anchors del Contenido/
    Scroll en vez de offsets fijos) — pedir confirmación antes.

## BLOQUE B — Profundidad: Laboratorio (Fase 6 del post-beta)
Encaja perfecto con el género idle; ya estaba como placeholder en el Home.

- [ ] `Laboratorio.gd` autoload (Dictionary de investigaciones, slots activos)
- [ ] ~15 investigaciones en categorías (principal / ataque / defensa / utilidad)
- [ ] **Timers offline** (`Time.get_unix_time_from_system()` para progreso con app cerrada)
- [ ] Aceleración con gemas + slot extra desbloqueable
- [ ] UI del Lab (lista, progreso, filtros)

## BLOQUE C — Negocio (Fases 8–9)
- [ ] **C1 · Monetización**
  - [ ] IAP (paquetes de gemas / bundles) — plugin Android
  - [ ] Ads (AdMob rewarded: gemas cada X horas)
  - [ ] Analytics (Firebase: ascensión, compras, tiempo jugado)
- [ ] **C2 · Eventos / retención**
  - [ ] Misiones diarias (3, reset 24h) — reusar `EstadisticasManager`
  - [ ] Hitos expandidos (hasta ~20) con recompensas

## BLOQUE D — Lanzamiento (Fase 10)
- [ ] Optimización para móvil low-end (draw calls, assets comprimidos)
- [ ] Arte 100% final + música completa (2–3 temas)
- [ ] Testing final con testers reales (0 crashes)
- [ ] Página de Google Play (capturas, vídeo, descripción) + publicación

## Aparcado / futuro
- Gacha (cartas + módulos) → posible v3.0
- Torneos, Misiones avanzadas, Alianzas (cards "soon" del Home)

---

### Orden recomendado
**A1 (audio) → A2/A5 (cerrar beta) → B (Laboratorio) → C → D.**
El audio es lo único grande que ambos documentos daban por hecho y que aún falta.
