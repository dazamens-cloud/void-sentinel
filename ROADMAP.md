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

- [~] **A1 · Audio** — SFX + música **sintetizados como propuesta** (`tools/gen_audio.py`).
  - [x] Autoload `AudioManager` (carga perezosa, pool de canales, volumen, loop WAV/OGG)
  - [x] SFX enganchados: disparo, muerte, crítico, daño al Nexus, compra, game over
  - [x] Música cableada: `combate` (en partida) y `menu` (en Home)
  - [x] Archivos generados proceduralmente en `res://audio/` (WAV; reemplazables 1:1)
  - [ ] Escuchar in-game y decidir: quedarse con los sintetizados, regenerarlos con
        otros parámetros, o sustituirlos por archivos definitivos (mismo nombre)
  - [ ] Para release: convertir la música a OGG (los WAV pesan ~3 MB cada uno)
- [x] **A2 · Tutorial básico** — 3 pantallas (Nexus / energía-mejoras-dron / ascensiones-
  Commander). `scripts/ui/TutorialOverlay.gd`, enganchado en `mundo.gd`. Solo en partidas
  nuevas, pausa el juego y persiste flag en `user://tutorial.save`. (commit 8e5cdc4)
- [ ] **A3 · Arte** — reemplazar placeholders clave (incremental, no bloqueante)
- [x] **A4 · Juice extra** — `FX.hit_pause()` (congelado breve con cooldown 0.8s):
  micro-pause en críticos; muertes de jefe/Commander con doble burst de partículas,
  sacudida fuerte y pause de 0.12s.
- [~] **A5 · Testing de beta** — pase visual completo hecho con `tools/UiTester.tscn`
  (capturas de todas las pantallas en `tools/caps/`); arreglados: panel de mejoras
  invisible en móvil (movido a CanvasLayer), cards del Home solapadas, Tienda rota,
  fuentes pequeñas en todo el menú. **Progreso reseteado** para probar el rebalanceo.
  - [ ] Jugar largo en el móvil con todo lo nuevo (Lab, Misiones, audio, interés nerfeado)
  - [ ] Regenerar APK (`/exportar-apk`) cuando el balance convenza
- [x] **A6 · Panel de Mejoras arreglado** — colapsable + altura dinámica al contenido,
  y visible en móvil (CanvasLayer). Cards nuevas de BONUS: interés ×2 y compras gratis ×3.
  QoL (commit dda438c): compra en ráfaga al mantener pulsado, MAX según energía
  disponible, coste dorado/rojizo, modal de info con valor → siguiente y coste,
  animaciones de panel/modal/pestañas, barra del dron reposicionada.

## BLOQUE B — Profundidad: Laboratorio (Fase 6 del post-beta) ✅ CÓDIGO HECHO
Implementado completo (commit cd7b0c0). Pendiente solo testing in-game y balance fino.

- [x] `Laboratorio.gd` autoload (`scripts/laboratorio/`, Dictionary de investigaciones, slots)
- [x] 15 investigaciones en 4 categorías (principal / ataque / defensa / utilidad)
- [x] **Timers offline** (`Time.get_unix_time_from_system()`; completa al reabrir la app)
- [x] Aceleración con **fragmentos** (no hay gemas aún; migrar a gemas cuando exista C1)
      + slot extra vía investigación "Despertar del Centinela"
- [x] UI del Lab (`scripts/ui/LabScreen.gd`: tabs, progreso, acelerar; card en el Home)
- [ ] Balance de costes/duraciones tras probarlo (valores iniciales conservadores)

## BLOQUE C — Negocio (Fases 8–9)
- [ ] **C1 · Monetización**
  - [ ] IAP (paquetes de gemas / bundles) — plugin Android
  - [ ] Ads (AdMob rewarded: gemas cada X horas)
  - [ ] Analytics (Firebase: ascensión, compras, tiempo jugado)
- [~] **C2 · Eventos / retención**
  - [x] Misiones diarias (3, reset 24h) — `MisionesManager` + `MisionesScreen`, pool de 8,
        selección determinista por fecha, recompensas en ecos/fragmentos (commit 0e00e04)
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
**A1 (audio) → A5 (testing de TODO lo nuevo + APK) → C1 (monetización) → C2 hitos → D.**
El audio es lo único grande que ambos documentos daban por hecho y que aún falta.
B (Laboratorio) y las misiones diarias de C2 ya están implementados a falta de testing.
