---
name: nueva-mejora
description: Añadir una mejora nueva al Workshop de Void Sentinel siguiendo el patrón de MejoraManager. Úsala cuando el usuario quiera crear/añadir una mejora, upgrade o stat comprable nuevo.
---

# Añadir una mejora al Workshop

Las mejoras viven en `scripts/mejoras/MejoraManager.gd`. Para añadir una correctamente
hay que tocar **3 sitios** (4 si necesita stat secundario). Lee siempre el archivo
actual antes de editar, porque los valores cambian.

## Antes de empezar, pregunta al usuario (si no lo dijo)
- **Categoría**: `ataque` / `defensa` / `bonificacion` / `commander`.
- **Qué hace** y si el incremento es **positivo** (sube algo) o **negativo** (reduce
  algo, p. ej. cadencia o daño recibido — estos llevan `min_valor`).
- `coste_base`, `incremento` por nivel y `max_nivel`.

## Pasos

### 1. Definir la entrada en el diccionario `mejoras`
Añádela en su bloque de categoría (`# ===== ATAQUE =====`, etc.) imitando las vecinas:
```gdscript
"mi_mejora": {
    "nombre": "Nombre Visible",
    "categoria": "ataque",
    "nivel": 0,
    "incremento": 1,        # o "incremento_xxx" si tiene varios efectos
    "coste_base": 12,
    "max_nivel": 50,
    "descripcion": "Texto que ve el jugador.",
    # opcionales:
    # "min_valor": 0.2,     # SOLO si incremento es NEGATIVO (suelo del valor final)
    # "max_valor": 0.5,     # tope del valor acumulado
    # "bloqueado": true,    # SOLO categoría commander
},
```
No hace falta añadir `nivel_nexo`: lo inicializa `_ready()` automáticamente.

### 2. Aplicar el efecto en `_aplicar_mejora()`
Añade un `match` case que llame al consumidor real (normalmente `NexusStats.set_mejora_xxx`).
- Si el stat es **multiplicativo** (como `danio`/`salud`): añádelo a la constante
  `MEJORAS_MULTIPLICATIVAS` y usa `get_multiplicador(mejora_id)`.
- Si es **bonificación** que otros sistemas (Economia/EconomiaEcos) leen bajo demanda:
  añade su id al `pass` del bloque de bonificación — no necesita aplicarse al instante.
- Si el método consumidor puede no existir, protégelo con `if NexusStats.has_method(...)`.

### 3. (Si tiene efecto secundario) `get_valor()` / `get_valor_secundario()`
Si la mejora usa `incremento_prob`/`incremento_danio` (como `disparo_critico`) o
`incremento_lentitud`/`incremento_empuje` (como `poder_pulso`), añade su case en
`get_valor()` y `get_valor_secundario()`.

### 4. Verificar el consumidor
Si llamas a un `NexusStats.set_mejora_xxx` que no existe aún, créalo en
`scripts/economia/NexusStats.gd` siguiendo los setters vecinos.

## Avisos
- **NO toques los `.tscn`** (regla del proyecto). La Uit del Workshop lee el diccionario
  por código; las cards se generan solas.
- El coste escala por categoría (factor 1.09/1.08/1.11/1.12) en `get_coste()` — no
  hay que tocar nada ahí salvo que crees una categoría nueva.
- Tras editar, ofrece probar con el modo prueba (`scripts/utils/ModoPrueba.gd`).
