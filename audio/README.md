# Audio de Void Sentinel

El `AudioManager` (autoload) carga estos archivos automáticamente si existen.
Suelta aquí los sonidos con **exactamente** estos nombres (extensión `.ogg`
recomendada para móvil; también valen `.wav` / `.mp3`):

## sfx/
| Archivo | Cuándo suena |
|---|---|
| `disparo`     | El Nexus dispara |
| `muerte`      | Muere un espectro |
| `critico`     | Impacto crítico |
| `dano_nexus`  | El Nexus recibe daño |
| `compra`      | Compra de mejora |
| `game_over`   | Cae el Nexus |

## music/
| Archivo | Cuándo suena |
|---|---|
| `menu`     | Pantalla de inicio / menú |
| `combate`  | Durante la partida (loop) |

> Si falta un archivo, ese sonido simplemente no se reproduce — el juego no
> falla. Fuentes gratis: freesound.org (SFX), pixabay.com/music, incompetech.com.
