# Void Sentinel

Idle Tower Defense vertical para Android, estilo *The Tower*.
Godot **4.6.2**, GL Compatibility, **720×1280 portrait**, GDScript.
Paquete: `com.dazamens.voidsentinel` · Repo: `dazamens-cloud/void-sentinel`

## Antes de tocar nada

1. **`docs/GDD.md` es la referencia del juego.** Empezar ahí, no por el código.
2. La nota de estado vive en el cerebro: `D:\cerebro\cerebro\Proyectos\Void-Sentinel.md`.
   Estado real, pendientes y gotchas ya resueltos. Actualizarla al terminar algo relevante.
3. **Los números del código no se copian a la documentación, se referencian con
   `fichero:línea`.** Copiarlos es lo que desincronizó a los ~45 documentos anteriores.

## Skills: cuál toca para qué

Hay 45 skills de Godot instaladas en `C:\Users\andre\.claude\skills\`, con descripciones
genéricas en inglés que casi nunca casan con cómo se describe el trabajo aquí. Esta tabla
las engancha directamente. **Invocarlas con la herramienta `Skill` antes de escribir código**,
no después.

| Si el trabajo es sobre… | Skill |
|---|---|
| Panel de mejoras: scroll, inercia, modal, gestos táctiles | `responsive-ui`, `mobile-development` |
| HUD de partida: fases, habilidades, dron, game over | `hud-system` |
| Menú: escalar pestañas y cabeceras (Forja, Perfil, Tienda, Lab, Misiones) | `godot-ui`, `responsive-ui` |
| Control nodes, themes, anclajes, contenedores | `godot-ui` |
| Escribir o ampliar las baterías de `tools/tests/` | `godot-testing` |
| Audio: buses, reproducción, conversión de formatos | `audio-system`, `assets-pipeline` |
| IAP, AdMob, permisos, ciclo de vida Android, firma | `mobile-development` |
| Cuelgues, leaks, errores raros en runtime | `godot-debugging` |
| Rendimiento, draw calls, memoria | `godot-optimization` |
| Animaciones y transiciones de UI | `tween-animation` |
| Partículas y efectos visuales | `particles-vfx` |
| Repasar código ya escrito antes de commitear | `godot-code-review` |
| Diseñar un sistema nuevo desde cero | `godot-brainstorming` |
| Juntar ramas, cerrar el trabajo | `finishing-a-development-branch` |

**Skills propias del proyecto** (`.claude/skills/`, ya se disparan solas):
`balance`, `exportar-apk`, `nueva-mejora`, `nuevo-enemigo`.

No aplican aquí y se pueden ignorar: multiplayer, XR, 3D, GDExtension, C#, dedicated-server.

## Cómo se verifica

Casi todos los bugs de este proyecto eran **invisibles leyendo el código**: compilaban sin
una queja. Lo que los saca es ejecutar y mirar.

251 comprobaciones en cinco baterías (`tools/tests/`):

```powershell
powershell -File tools\tests\ejecutar-pruebas.ps1
```

Capturas del menú y la partida sin jugar (deja PNGs en `tools/caps/`):

```
godot --path . tools/UiTester.tscn -- --mudo
```

`-- --mudo` arranca en silencio. El runner respalda y restaura `user://` **desde fuera de
Godot**: los autoloads guardan al cerrarse, después de cualquier restauración interna, y
machacaban la partida del jugador.

Las pruebas son headless y solo verifican lógica: **no dicen nada de cómo se ve ni de si el
balance es divertido**. Para eso, capturas o el móvil.

## Gotchas de este proyecto

- **Los emoji fuera del BMP no se pintan en Android** — ni las fuentes del proyecto ni el
  fallback los cubren. En Windows sí, así que el fallo solo aparece en el móvil. Los
  símbolos geométricos (◈ ◆) sí funcionan. Usar `IconoVec` en su lugar.
- **`AscensionManager` no es autoload**: vive como nodo en `mundo.tscn`. Usarlo como global
  da un error de parseo que deja el script sin cargar y Godot se queda vivo sin cerrarse
  (parece un cuelgue).
- **`flat = true` en un `Button` hace que Godot ignore sus `StyleBox`.** Aparecía en el Nexo
  y la Forja: los botones se veían como texto suelto.
- **Un `Button` no es contenedor**: los hijos no se colocan solos. Meterlos en un
  `MarginContainer` anclado a todo el botón.
- **El panel de mejoras se pinta encima de cualquier overlay de `Interfaz`**: vive en
  `CapaUI`, otra `CanvasLayer` en la misma capa pero posterior en el árbol, y el
  `z_index` no cruza capas. La pausa y el game over lo ocultan; un overlay nuevo también.
- **En el móvil, un `ScrollContainer` no se desplaza si el dedo empieza sobre un botón**,
  aunque tenga `mouse_filter = PASS`. En el PC no se nota porque allí se usa la rueda.
  Solución en `MejoraCard`: a partir de 16 px de arrastre la card mueve `scroll_vertical`
  y consume el evento.
- **El cero de Orbitron es un rectángulo con barra diagonal**, casi idéntico al glifo de
  "carácter no soportado". Con las estadísticas a cero la pantalla parece rota sin estarlo.
- **El JDK de los ajustes del editor debe apuntar al JDK 17 de `D:`.** Apuntaba a una carpeta
  borrada de `C:` y la exportación de Android estaba rota sin que nadie lo supiera.
- **Godot mata el servidor de `adb` al salir** (*shutdown adb on exit*): exportar el APK
  tumba una sesión de `adb` ya abierta. Exportar **antes** de conectar con el móvil.
- **El puerto de la depuración inalámbrica cambia** al reiniciar el móvil; `adb mdns
  services` lo descubre sin volver a vincular.
- **Una clase nueva con `class_name` no existe hasta que Godot escanea el proyecto**:
  `godot --headless --editor --quit`. Si no, las pruebas fallan con *Identifier not
  declared* aunque el fichero esté bien.
- **Xiaomi/HyperOS bloquea por partida doble**: instalar por adb necesita *"Instalar vía
  USB"*; simular toques necesita además *"Depuración USB (Ajustes de seguridad)"*.

## Por qué el menú se ve como se ve

Los mockups (`docs/mockups/`) se diseñaron a **390 px de ancho** y sus valores se copiaron
literales a un viewport de **720**: todo el menú quedó a escala 0,54. `MenuTheme` escala ×1,85.

Los iconos **no son glifos de fuente**: `IconoVec.gd` dibuja 18 formas con `_draw()`. Se
eligió frente a PNGs porque no hay ficheros que importar ni mantener, se ven nítidos a
cualquier densidad y el color va por parámetro.

## Archivos clave

| Ruta | Qué es |
|---|---|
| `docs/GDD.md` | La referencia del juego |
| `docs/HUD-rediseno.md` | Plan del siguiente trabajo |
| `docs/mockups/` | Diseño original de las pantallas |
| `scripts/ui/MenuTheme.gd` | Escalado y estilo del menú |
| `scripts/ui/IconoVec.gd` | Los 18 iconos vectoriales |
| `scripts/utils/EscaladoEnemigos.gd` | Fuente única de la dificultad |
| `tools/tests/` | Cinco baterías y su runner |
| `tools/UiTester.gd` | Capturas automáticas |

## Ramas

Rama actual: `feat/ui-escala-mockup`, que sale de `fix/panel-mejoras` (PR #1 abierto) con
19 commits encima. **Está pendiente decidir cómo juntarlas** — preguntar antes de hacer
nada que dé por resuelto ese cruce.
