class_name MenuTheme
extends Node
# ============================================================
# MenuTheme.gd
# Paleta de colores, fuentes y constantes de estilo del menu.
# Equivalente a las variables CSS del prototipo HTML.
#
# NO es un Autoload: es una clase de utilidad estatica.
# Se accede con MenuTheme.CYAN, MenuTheme.GOLD, etc.
#
# Para usarlo como libreria global, anade "class_name MenuTheme"
# (ya incluido abajo) y llama directamente MenuTheme.CYAN
# desde cualquier script sin instanciar.
# ============================================================



# ---- COLORES BASE (fondo) ----
const BG_DEEP    := Color("020409")
const BG_MID     := Color("060c14")
const BG_CARD    := Color("0a1525")

# ---- ACENTOS ----
const CYAN       := Color("00e5ff")
const GOLD       := Color("ffd740")
const VIOLET     := Color("b388ff")
const GREEN      := Color("69ff47")
const RED        := Color("ff5252")
const MAGENTA    := Color("e040fb")

# ---- TEXTO ----
const TEXT_PRIMARY := Color("e8f4fd")
const TEXT_MUTED   := Color("4a7a9b")

# ---- BORDES (con alpha) ----
const BORDER_GLOW := Color(0.0, 0.898, 1.0, 0.18)   # cyan 18%
const BORDER_DIM  := Color(0.0, 0.898, 1.0, 0.06)   # cyan 6%

# ---- COLORES POR CATEGORIA NEXO ----
const CAT_ATAQUE       := Color("ff6b6b")
const CAT_DEFENSA      := Color("00e5ff")
const CAT_BONIFICACION := Color("ffd740")

# ---- COLOR FORJA / FRAGMENTOS ----
const FRAG := Color("b388ff")

# ---- RAREZAS ----
const R_COMUN      := Color("78909c")
const R_RARO       := Color("00e5ff")
const R_EPICO      := Color("b388ff")
const R_LEGENDARIO := Color("ffd740")


# ============================================================
# TAMANOS DE FUENTE (px)
# ============================================================
const FS_TITLE   := 22
const FS_HEADER  := 16
const FS_BODY    := 12
const FS_SMALL   := 10
const FS_TINY    := 8


# ============================================================
# SIMBOLOS (asignados por codigo, nunca en .tscn)
# Usar estas constantes evita pegar unicode suelto por el codigo.
# ============================================================
const SYM_ECOS      := "\u25C8"   # diamante con punto
const SYM_FRAG      := "\u25C6"   # diamante relleno
const SYM_ENERGIA   := "\u26A1"   # rayo
const SYM_GEM       := "◇"   # rombo hueco (la fuente no trae el emoji gema)
const SYM_HOME      := "\u2302"   # casa
const SYM_PERFIL    := "\u2B21"   # hexagono
const SYM_TIENDA    := "\u2B19"   # diamante con linea
const SYM_PLAY      := "\u25B6"   # triangulo play
const SYM_ARROW_R   := "\u203A"   # flecha derecha
const SYM_SKULL     := "\U0001F480" # calavera


# ============================================================
# FUENTES
# Devuelve la fuente cargada desde res://fonts/ si existe,
# o null (Godot usa la fuente por defecto) si aun no las has
# importado. Asi el menu no crashea aunque falten las fuentes.
#
# DESCARGA recomendada (Google Fonts, gratis):
#   - Orbitron  -> res://fonts/Orbitron.ttf   (titulos / HUD)
#   - Rajdhani  -> res://fonts/Rajdhani.ttf   (texto cuerpo)
# ============================================================
static func get_font_hud() -> Font:
	var path := "res://fonts/Orbitron.ttf"
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func get_font_body() -> Font:
	var path := "res://fonts/Rajdhani.ttf"
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ============================================================
# HELPERS DE ESTILO
# Crean StyleBoxFlat reutilizables (equivalente a las clases CSS).
# ============================================================

# Panel con fondo oscuro semitransparente y borde tenue.
static func make_card_style(border_color: Color = BORDER_DIM, bg_alpha: float = 0.85) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(BG_MID.r, BG_MID.g, BG_MID.b, bg_alpha)
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

# Estilo de boton de compra/accion con color de acento.
static func make_button_style(accent: Color, filled: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if filled:
		sb.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
	else:
		sb.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.30)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

# Barra de progreso (track de fondo).
static func make_progress_track() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.set_corner_radius_all(2)
	return sb

# Barra de progreso (relleno con color).
static func make_progress_fill(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(2)
	return sb
