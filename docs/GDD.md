---
version: 0.7
actualizado: 2026-09-08
sustituye_a: GDD v0.6 (junio 2026) y todos los documentos listados en la sección 8
---

# Void Sentinel — Documento de diseño y estado (v0.7)

> **Cómo se usa este documento.** Es el punto de entrada único del proyecto: si
> trabajas desde otra máquina, otra sesión o con otra IA, empieza aquí.
>
> **La regla que lo mantiene vivo:** los números que ya viven en el código **no se
> copian aquí**, se referencian con `fichero:línea`. Copiarlos es exactamente lo
> que desincronizó a todos los documentos anteriores (sección 8). Si necesitas un
> valor, ábrelo en el código: ahí siempre estará el bueno.

---

## 1. Qué es

Idle Tower Defense móvil en vertical. El jugador **no mueve** al Nexus: este
dispara solo, y su decisión está en **qué mejorar y cuándo gastar**. Cada run
deja progreso permanente.

| | |
|---|---|
| Motor | Godot 4.6.2, GDScript |
| Resolución | 720×1280, portrait, stretch `canvas_items` |
| Plataforma | Android — `com.dazamens.voidsentinel` |
| Repositorio | github.com/dazamens-cloud/void-sentinel |
| Renderer | GL Compatibility |

---

## 2. Estado real

Dos columnas separadas **a propósito**. "Código" significa que existe y compila;
"probado", que algo lo verificó. Mezclarlas fue lo que dio por bueno un proyecto
que fallaba, y acabó provocando la pausa de julio.

Leyenda: ✅ sí · ❓ sin verificar · ⚙️ verificado por pruebas automáticas ·
👁️ verificado visualmente

| Sistema | Código | Probado |
|---|:---:|:---:|
| Escalado de enemigos (curva y tope) | ✅ | ⚙️ |
| Economía: energía, ecos, fragmentos | ✅ | ⚙️ |
| Interés (tasa, cap y reset) | ✅ | ⚙️ |
| Mejoras in-run: costes, compra, topes | ✅ | ⚙️ 👁️ |
| Panel de mejoras (abrir, pestañas, modal) | ✅ | 👁️ |
| Oleadas y ascensiones | ✅ | ⚙️ 👁️ |
| Combate del Nexo (escudo, defensa, crítico, cadencia) | ✅ | ⚙️ |
| Ciclo de vida de espectros (daño, muerte, recompensa) | ✅ | ⚙️ |
| Laboratorio: 15 investigaciones + timers offline | ✅ | ⚙️ |
| Misiones diarias: 3 de 8, reset de medianoche | ✅ | ⚙️ |
| Menú: 7 pantallas y navegación | ✅ | ⚙️ 👁️ |
| Forja: 8 habilidades | ✅ | ⚙️ 👁️ |
| Barra de habilidades en partida | ✅ | 👁️ |
| Reanudar partida (checkpoint) | ✅ | ⚙️ |
| Persistencia en disco | ✅ | ⚙️ |
| Dron recolector | ✅ | ❓ |
| Commander | ✅ | ❓ |
| Tutorial de primera partida | ✅ | ❓ |
| Disparos especiales | ✅ | ❓ |
| Audio (música y SFX) | ✅ | ❓ |
| Colisiones y proyectiles | ✅ | ❓ |
| Comportamiento en Android real | ✅ | ❓ |

**Lo que ⚙️ NO cubre:** las pruebas son headless y verifican lógica. No dicen
nada de cómo se ve, cómo se siente, ni de si el balance es divertido.

---

## 3. Arquitectura

### Autoloads

Definidos en `project.godot`, sección `[autoload]`.

| Autoload | Fichero | Responsabilidad |
|---|---|---|
| `Economia` | `scripts/economia/EconomiaEcos.gd` | Energía, ecos, fragmentos, interés, ascensiones |
| `NexusStats` | `scripts/economia/NexusStats.gd` | Stats del Nexo: vida, daño, escudo, crítico |
| `MejoraManager` | `scripts/mejoras/MejoraManager.gd` | Mejoras in-run y permanentes del Nexo |
| `Sistemadisparosespeciales` | — | Disparos especiales y Commander |
| `HabilidadManager` | `scripts/habilidades/HabilidadManager.gd` | Las 8 habilidades de la Forja |
| `HabilidadEjecutor` | `scripts/habilidades/HabilidadEjecutor.gd` | Ejecución y cooldowns |
| `EstadisticasManager` | `scripts/perfil/EstadisticasManager.gd` | Kills, récords, logros |
| `MisionesManager` | `scripts/perfil/MisionesManager.gd` | Misiones diarias |
| `Laboratorio` | `scripts/laboratorio/Laboratorio.gd` | Investigaciones con timers reales |
| `ModoPrueba` | `scripts/utils/ModoPrueba.gd` | Estado avanzado para testing |
| `FX` | `scripts/utils/FX.gd` | Screen shake, hit pause |
| `ReanudarPartida` | `scripts/utils/ReanudarPartida.gd` | Checkpoint de la run |
| `AudioManager` | `scripts/utils/AudioManager.gd` | Música y pool de SFX |

**`AscensionManager` NO es autoload**: vive como nodo en `escenas/mundo.tscn`.
Usarlo como global da un error de parseo que deja el script sin cargar.

### UI

El menú está construido **por código, sin `.tscn`**. `Mainmenu.gd` orquesta las
7 pantallas mediante `navigate(nombre)`; cada pantalla es un `Control` que se
monta solo. El HUD y el panel de mejoras sí usan escenas.

---

## 4. Dónde está cada número

**No los copies a este documento.** Ábrelos:

| Qué | Dónde | Cómo tunearlo |
|---|---|---|
| Curva de dificultad | `scripts/utils/EscaladoEnemigos.gd:25` | Sube `EXP_VIDA` para endurecer |
| Stats base por tipo de enemigo | `scripts/utils/EscaladoEnemigos.gd:30` | Diccionario `BASE` |
| Tasa y cap de interés | `scripts/economia/EconomiaEcos.gd:32` | |
| Las 25 mejoras y sus costes | `scripts/mejoras/MejoraManager.gd:27` | |
| Factor de coste por categoría | `scripts/mejoras/MejoraManager.gd:327` | |
| Las 15 investigaciones | `scripts/laboratorio/Laboratorio.gd:29` | |
| Pool de misiones | `scripts/perfil/MisionesManager.gd:22` | |
| Ritmo de oleadas y topes | `scripts/utils/AscensionManager.gd:33-39` | |

`EscaladoEnemigos` es la **fuente única** de la dificultad: si generas enemigos
en cualquier otro sitio, úsala. Antes las fórmulas estaban duplicadas y se
desincronizaron — el Commander llegó a invocar enemigos de millones de HP.

---

## 5. Pruebas

204 comprobaciones headless en cuatro baterías:

```
powershell -File tools\tests\ejecutar-pruebas.ps1
```

| Batería | Cubre |
|---|---|
| `TestSistemas` | Escalado, economía, interés, mejoras, Lab, misiones |
| `TestPantallas` | Las 7 pantallas montan y navegan |
| `TestCombate` | Escudo, defensa, crítico, cadencia, espectros |
| `TestProgresion` | Oleadas, ascensiones, checkpoint de reanudar |

El runner **respalda y restaura `user://` desde fuera de Godot**: los autoloads
guardan al cerrarse, después de cualquier restauración interna, y machacaban la
partida del jugador.

Para ver el juego sin jugarlo, el tester de UI deja capturas PNG en
`tools/caps/`:

```
godot --path . tools/UiTester.tscn -- --mudo
```

`-- --mudo` arranca en silencio, y solo esa ejecución.

---

## 6. Gotchas del entorno

- **PowerShell 5.1** no acepta `&&`. `Start-Process` no entrecomilla los
  argumentos y **la ruta del proyecto lleva un espacio**: hay que citarla o Godot
  recibe `D:\proyectos` y aborta. `Select-String` es *case-insensitive* por
  defecto, así que buscar `FALLO` casa también con "0 fallos".
- **Capturar la salida de Godot**: por tubería se pierde y `2>&1` la envuelve en
  `ErrorRecords`. Redirige a fichero.
- `python` desde la shell no funciona (alias de Microsoft Store): usa la ruta
  completa del intérprete.
- Consola en cp1252: los emojis rompen los scripts de Python que no llamen a
  `sys.stdout.reconfigure`.

---

## 7. Pendiente

- [ ] **Probar en Android real** — nada de lo verificado lo está en dispositivo
- [ ] Audio: 8 ficheros WAV (6,1 MB) sin convertir a OGG
- [ ] Cubrir con pruebas: Dron, Commander, tutorial, disparos especiales
- [ ] Monetización: IAP y AdMob
- [ ] Arte (placeholders; no bloquea) y ficha de Play Store
- [ ] *Leak* de 1 recurso al cerrar (preexistente, no afecta al juego)

---

## 8. Documentos superados

Ninguno describe el juego actual. **No los uses como referencia**: se conservan
solo como historia.

| Documento | Qué describe | Por qué no sirve |
|---|---|---|
| `files/*.md` (8 ficheros) | Derivado del GDD v0.6 | Copió sus números; dice que Multidisparo y Rebote están pendientes cuando ya funcionan |
| GDD v0.6 (Drive, junio) | 4 monedas con Platino, `TorreStats.gd`, guardado en `.cfg`, hub de 5 pestañas | El proyecto se reescribió después |
| Drive, mayo | Comparativas con *The Tower*, DOC A/B, roadmaps | Planificación previa; además, muy duplicada |
| Drive, abril | "VOI SENTINEL" | Proyecto anterior, con otro nombre |
| Chats de DeepSeek | `TorreStats`, `nucleo.gd`, `GestorOleadas`, o fases intermedias | Esos ficheros ya no existen, o sus consejos ya se aplicaron |

**Los tres errores que más se repiten**, por si vuelves a leerlos:

1. **Escalado exponencial `1.38^oleada`.** Es el modelo viejo: se rompía por
   encima de la ascensión 40. Hoy la curva es polinómica.
2. **Interés al 2,5% con cap 3000.** Se nerfeó en junio porque disparaba la
   energía y trivializaba el mid-game.
3. **Coste base 300 en las mejoras.** Los reales son de un orden muy inferior.

El **porqué** de estas decisiones vive en el cerebro
(`D:\cerebro\cerebro\Proyectos\Void-Sentinel.md`), no aquí. Este documento
guarda el *qué*; el vault, el *por qué*.
