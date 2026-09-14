# Referencia de diseño: The Tower – Idle Tower Defense

> **Solo referencia.** Void Sentinel se inspira en este juego, pero no se copia
> nada: el objetivo es entender qué sistemas tiene y por qué funcionan, para
> decidir con criterio qué añadir y en qué diferenciarse.
>
> Fuente: wiki comunitaria `the-tower-idle-tower-defense.game-vault.net`
> (consultada el 2026-09-14).

## Mapa de sistemas

| The Tower | Void Sentinel | Estado |
|---|---|---|
| Cash (moneda de partida) | Energía | Equivalente |
| Coins → Workshop y Lab | Ecos → Nexo y Laboratorio | Equivalente |
| Workshop | Mejoras del Nexo (+ mejoras in-run) | Equivalente |
| Lab con tiempos de investigación | Laboratorio, 15 investigaciones offline | Equivalente |
| Daily Missions | Misiones diarias (3 de 8) | Equivalente |
| Enemies, élites y jefes | 6 espectros + Commander | Equivalente |
| Power Stones → Ultimate Weapons | Fragmentos → Forja (8 habilidades) | Distinto a propósito (ver abajo) |
| Gems (moneda premium) | Gemas en la Tienda | Hueco sin lógica |
| Tournament | Torneos "próximamente" | Hueco sin lógica |
| Cards | — | No existe |
| Modules | — | No existe (hubo mockup descartado) |
| Perks | — | No existe |
| Events / Medals | — | No existe |
| Milestones | — | No existe |

### Qué es cada sistema que falta

- **Cards**: gacha de cartas con efectos que se equipan en un número limitado de
  ranuras. Se mejoran consiguiendo copias. Algunas se bloquean durante la
  partida o mientras hay un jefe vivo.
- **Modules**: equipo por categorías (ataque, defensa, economía, armas
  definitivas), uno de cada. Tienen rareza, suben de nivel con fragmentos y se
  fusionan para subir de rareza.
- **Perks**: elecciones que se van ofreciendo durante la partida.
- **Events / Medals**: eventos temporales con su propia moneda y tienda.
- **Milestones**: recompensas por alcanzar oleadas concretas.

**El mockup descartado de la Forja** (`docs/mockups/ForjaScreen_VoidSentinel.html`,
módulos con rareza ÉPICO/RARO y ranuras) es prácticamente el concepto de *Modules*.
La idea ya se tuvo; se aparcó en favor de las habilidades.

## Lecciones de diseño

Ideas a considerar, no mecánicas que calcar.

1. **Decisiones con coste, no solo números más grandes.** Buena parte de sus perks
   mejoran algo a cambio de empeorar otra cosa (más daño a cambio de jefes más
   duros, más monedas a cambio de menos vida). Eso hace que dos partidas se
   jueguen distinto. Hoy casi todas las mejoras de Void Sentinel son "sube un
   stat": no hay dilemas.
2. **Elegir entre opciones aleatorias.** Al comprar un arma definitiva se ofrecen
   varias al azar y el jugador escoge. Da variedad sin necesitar más contenido.
3. **Si hay gacha, protección contra la mala suerte.** Lo que ya está al máximo sale
   del bote y hay un objeto raro garantizado tras cierto número de intentos. Es la
   diferencia entre un gacha que frustra y uno que se tolera.
4. **El interés es delicado en los dos juegos.** Su comunidad lo considera un perk
   inútil; en Void Sentinel hubo que nerfearlo en junio por el motivo contrario,
   porque disparaba la energía y rompía el mid-game.

## Dónde Void Sentinel ya se diferencia

- **Las habilidades de la Forja son activas**: el jugador decide cuándo lanzarlas.
  En The Tower las armas definitivas son esencialmente automáticas y la estrategia
  consiste en sincronizar sus tiempos.
- **El Commander**, con sus invocaciones que se saltan el tope de enemigos, no tiene
  equivalente directo.

Son la identidad propia del juego. Al añadir sistemas nuevos conviene reforzarlos,
no diluirlos copiando el modelo de referencia.
