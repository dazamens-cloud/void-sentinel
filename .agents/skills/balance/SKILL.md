---
name: balance
description: Revisar o ajustar el balance de Void Sentinel (dificultad de enemigos, costes y escalado de mejoras). Úsala cuando el usuario hable de balancear, ajustar dificultad, curvas, costes, "el juego está muy fácil/difícil" o tunear progresión.
---

# Balance de Void Sentinel

El balance está centralizado en pocos sitios a propósito. Antes de tocar nada, lee el
archivo correspondiente y explícale al usuario el efecto de cada constante.

## Dificultad de enemigos — `scripts/utils/EscaladoEnemigos.gd`
**Fuente ÚNICA** de la curva de dificultad (modelo polinómico):
- `EXP_VIDA` (2.0) — sube para endurecer, baja para suavizar. Es el más sensible.
- `EXP_ATAQUE` (1.25) — cuánto pega el enemigo según ascensión.
- `EXP_RECOMPENSA` (1.15) — energía ganada por ascensión.
- Diccionario `BASE` — stats a ascensión 0 por tipo.

Fórmula: `stat = base × (1+asc)^EXP`. ⚠️ No reintroduzcas exponenciales tipo `1.38^asc`:
se rompían sobre la ascensión 40 (enemigos de millones de HP). Por eso es polinómico.

## Escalado de mejoras — `scripts/mejoras/MejoraManager.gd`
- `FACTOR_MULTIPLICATIVO` (1.03) — daño y salud escalan `base × 1.03^nivel` (compuesto).
  `MEJORAS_MULTIPLICATIVAS` lista cuáles. Subirlo dispara el techo de poder del jugador.
- **Coste de mejoras** (`get_coste` / `get_coste_nexo`): factor por categoría
  — ataque 1.09, defensa 1.08, bonificacion 1.11, commander 1.12. Coste =
  `coste_base × factor^nivel`. Subir el factor encarece la progresión.
- `coste_base`, `incremento`, `max_nivel` por mejora en el diccionario `mejoras`.

## Cómo trabajar el balance
1. Pregunta el objetivo: ¿más difícil al principio? ¿techo más alto? ¿run más largas?
2. Cambia **una constante a la vez** y razona el impacto antes de tocar.
3. Para comprobar, usa el **modo prueba** (`scripts/utils/ModoPrueba.gd`) que permite
   saltar a ascensiones altas sin grindear.
4. Si cambias números, calcula 2-3 puntos de la curva (asc 1, 10, 50) y muéstraselos
   al usuario para que vea el efecto antes de dar por bueno el cambio.

## Avisos
- No dupliques fórmulas fuera de estos archivos: el bug histórico fue tener la curva
  copiada en `AscensionManager` y `EspectroComander` y que se desincronizaran.
- El interés/economía vive en `scripts/economia/`. Si el ajuste es de ecos/energía
  ganada, revisa `EconomiaEcos.gd` además del escalado.
