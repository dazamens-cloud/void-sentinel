# Estudio: rediseño del HUD de partida

> Estado: **propuesta, sin implementar**. Escrito el 2026-09-09 para retomarlo
> en la siguiente sesión.

## 1. El problema

El menú ya sigue una estética propia (tarjetas, `MenuTheme`, iconos vectoriales,
tipografía con jerarquía). El HUD de partida se quedó en el prototipo, y el
contraste se nota: parece otro juego. En palabras del autor, *"cinemáticas
premium y luego el juego es una caca"*.

No es una impresión: es medible.

| | HUD (`Interfaz.gd`) | Menú (`Nexoscreen.gd`) |
|---|---|---|
| Usos de `MenuTheme` | **0** | 36 |
| `StyleBox` (fondos, bordes, radios) | **0** | 5 |
| Colores escritos a mano | 21 | — |
| Posiciones absolutas `Vector2(x, y)` | 19 | — (usa contenedores) |

Las dos consecuencias:

1. **No comparte sistema visual.** Ni la paleta, ni las fuentes, ni los radios,
   ni los iconos. Cada elemento se pintó por separado.
2. **No se adapta.** 19 posiciones absolutas calculadas sobre 720×1280. En el
   móvil de pruebas (1220×2712, ratio 22:9) el contenido queda repartido de
   forma arbitraria porque nadie decide dónde va: está clavado a mano.

## 2. Inventario de lo que hay hoy

| Elemento | Cómo está | Qué falla |
|---|---|---|
| Ascensión | Label "Ascensión: 1" centrado | Texto plano, sin contenedor ni jerarquía |
| Recursos | `"◈ %s"` en tres labels sueltos | El icono es un **carácter**, no un icono |
| Vida | Label `"99 / 100"` en verde | Es el dato más crítico y **no tiene barra** |
| Barra de ascensión | `ProgressBar` por defecto | Gris de Godot, ajena a la paleta |
| Barra del dron | `ProgressBar` + label encima | Descolocada, tamaño de prototipo |
| Botón de pausa | `Button` sin estilo | Cuadro gris del tema por defecto |
| Barra de habilidades | Botones `flat` sin fondo | Se leen como texto suelto, no como botones |
| Panel de mejoras | **Ya rediseñado** | ✅ es la referencia a seguir |

## 3. Propuesta

La idea rectora: **el HUD debe parecer el mismo producto que el menú**, sin
robar protagonismo al combate. El menú puede permitirse tarjetas grandes; el
HUD tiene que informar sin tapar la acción.

### 3.1 Barra superior — una tarjeta, no labels sueltos

Un `PanelContainer` con `MenuTheme.make_card_style()`, fondo semitransparente y
el mismo radio que las tarjetas del menú, conteniendo:

- **Ascensión** a la izquierda, con su número destacado y la etiqueta pequeña
  encima (mismo patrón que las stats del Perfil).
- **Los tres recursos** con `IconoVec` de verdad (`ROMBO_PUNTO` ecos, `ROMBO`
  fragmentos, `RAYO` energía), cifra grande y unidad apagada, igual que las
  cards del Nexo.
- La barra de ascensión integrada **dentro** de la tarjeta, no flotando.

### 3.2 La vida, como barra

Hoy es un texto. Debería ser una barra con el mismo tratamiento que las del
menú (degradado, radio, fondo al 6%), con color según el tramo: cian llena,
dorado a media vida, rojo por debajo del 25%. El número, encima y pequeño.

Y el **escudo** merece su propia franja fina sobre la vida: existe en
`NexusStats` y ahora mismo el jugador no lo ve en ninguna parte.

### 3.3 Habilidades, como botones de verdad

Cada habilidad en una caja tintada con su color, `IconoVec` dentro y el
cooldown como anillo de progreso alrededor del icono en vez de un texto
"LISTA". Es el patrón estándar del género y encaja con lo que ya hicimos.

### 3.4 Botón de pausa

Redondo, con `StyleBoxFlat` y borde tenue del color de acento, como las
píldoras de recursos del menú.

### 3.5 Dron

Su barra, hoy suelta abajo a la izquierda, pasa a una píldora pequeña con
`IconoVec` y el contador "12/50" — el mismo lenguaje que el resto.

## 4. Cómo abordarlo

Por fases, verificando con capturas después de cada una:

1. **Migrar a contenedores.** Sustituir las 19 posiciones absolutas por
   `MarginContainer` + `VBox/HBox` anclados. Es el cambio que más riesgo tiene
   (puede descolocar cosas) y el que más beneficio da: el HUD pasa a adaptarse
   a cualquier ratio.
2. **Aplicar `MenuTheme`.** Sustituir los 21 colores a mano y las fuentes
   sueltas por las constantes del tema.
3. **Barra superior** como tarjeta, con `IconoVec`.
4. **Vida y escudo** como barras.
5. **Habilidades y pausa.**

Cada fase es independiente y se puede parar en cualquier punto.

## 5. Riesgos

- **`Interfaz.gd` son 607 líneas** y toca combate, game over, pausa y Commander.
  No es solo presentación: hay lógica mezclada. Conviene no reescribirlo entero
  de golpe.
- **El HUD no tiene pruebas.** `TestPantallas` cubre el menú, no la interfaz de
  partida. Antes de tocar convendría una batería mínima que compruebe que el
  HUD se monta y responde a las señales de `Economia` y `NexusStats`.
- **Verificar en móvil cada fase**, no solo en escritorio: el ratio 22:9 del
  dispositivo de pruebas es donde antes aparecieron las sorpresas.

## 6. Referencias

- Estética a seguir: `scripts/ui/Nexoscreen.gd` y `scripts/ui/ForjaScreen.gd`
- Sistema visual: `scripts/ui/MenuTheme.gd`, `scripts/ui/IconoVec.gd`
- Capturas: `godot --path . tools/UiTester.tscn -- --mudo` deja PNGs en
  `tools/caps/` (incluye `mundo_*` con el HUD en partida)
