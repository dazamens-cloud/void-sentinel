---
name: nuevo-enemigo
description: Crear un tipo de espectro (enemigo) nuevo en Void Sentinel replicando el patrón de los espectros existentes. Úsala cuando el usuario quiera añadir un enemigo, espectro o tipo de bicho nuevo.
---

# Añadir un tipo de espectro

Los enemigos se llaman "espectros". Añadir uno toca **4 sitios**. Lee siempre los
archivos actuales antes de editar.

## Antes de empezar, pregunta al usuario (si no lo dijo)
- **Nombre/tipo** (string corto en minúscula, p. ej. `"veloz"`).
- **Comportamiento**: ¿persigue y golpea cuerpo a cuerpo (como `tanque`), corre y
  explota (`kamikaze`), dispara a distancia (`sniper`)? Esto decide de qué espectro
  copiar el script.
- **Stats base** a ascensión 0: hp, atk, spd, recompensa.
- **Cuándo aparece**: a partir de qué ascensión y con qué probabilidad.

## Pasos

### 1. Script del enemigo — `scripts/enemigos/EspectroX.gd`
Duplica el espectro más parecido (`EspectroTanque.gd`, `EspectroKamikaze.gd` o
`EspectroSniper.gd`) y ajusta:
- `tipo_espectro` y el `print` de `_ready()`.
- Stats por defecto (los reescribe `configurar()` con el escalado, no son críticos).
- La lógica de `_physics_process()` según el comportamiento.
- Mantén intactos: `configurar(datos)`, `recibir_dano()`, `_destruir()` (suelta
  TextoFlotante + Explosion + Fragmento y llama a `Economia.procesar_drop_espectro`).
- `add_to_group("espectros")` y `add_to_group("nexus")` — no los quites.

### 2. Escena `.tscn` — la hace el usuario en el editor
**NO crees ni edites .tscn a mano** (regla del proyecto). Indícale al usuario que
duplique la escena del espectro base en el editor de Godot, le asigne el nuevo script
y guarde en `escenas/enemigos/` (o donde estén las demás).

### 3. Stats base — `scripts/utils/EscaladoEnemigos.gd`
Añade una fila al diccionario `BASE` con `hp/atk/spd/recompensa`. El escalado por
ascensión (`pow(asc+1, EXP_*)`) se aplica solo; solo defines la base. Esta es la
**fuente única** de dificultad: no dupliques fórmulas en otro sitio.

### 4. Spawn — `scripts/utils/AscensionManager.gd`
- Añade `@export var escena_espectro_x: PackedScene` (el usuario la asigna en el editor).
- En la función de elección de escena (mira el patrón `if ascension >= N and ... and randf() < P`),
  añade la regla de aparición de tu enemigo (umbral de ascensión + probabilidad).
- En el mapeo escena→string (`elif escena_elegida == escena_espectro_x: tipo_str = "x"`),
  añade tu tipo para que reciba los stats correctos de `EscaladoEnemigos`.

## Avisos
- El `tipo` string debe coincidir EXACTO en los 3 sitios: el script, `BASE` y el
  mapeo de `AscensionManager`. Un typo = stats de `basico` por fallback silencioso.
- Tras editar, recuérdale al usuario que en el editor debe arrastrar la nueva escena
  al campo `@export` del nodo que tenga `AscensionManager`.
