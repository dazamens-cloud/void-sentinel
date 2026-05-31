extends Control

# ============================================================================
# HOME SCREEN - Pantalla principal del hub
# ============================================================================

signal play_pressed

# Nodos
@onready var lbl_gold       = $VBox/CoinsBar/GoldBadge/HBox/LblGold
@onready var lbl_frag       = $VBox/CoinsBar/FragBadge/HBox/LblFrag
@onready var lbl_plat       = $VBox/CoinsBar/PlatBadge/HBox/LblPlat
@onready var lbl_tier_name  = $VBox/TierBadge/LblTierName
@onready var lbl_ascension  = $VBox/StatsRow/StatAscension/VBox/LblVal
@onready var lbl_partidas   = $VBox/StatsRow/StatPartidas/VBox/LblVal
@onready var lbl_commanders = $VBox/StatsRow/StatCommanders/VBox/LblVal
@onready var btn_jugar      = $VBox/BtnJugar
@onready var core_inner     = $VBox/NucleoCentro/CoreInner
@onready var core_outer     = $VBox/NucleoCentro/CoreOuter
@onready var dots           = [
	$VBox/TierBadge/DotsContainer/Dot1,
	$VBox/TierBadge/DotsContainer/Dot2,
	$VBox/TierBadge/DotsContainer/Dot3,
]

const TIER_NAMES = {
	1: "I — Void Initiate",
	2: "II — Void Adept",
	3: "III — Void Master",
}
const TIER_THRESHOLDS = [0, 5000, 15000]
const COLOR_CIAN = Color(0.0, 0.898, 1.0)
const COLOR_DOT_OFF = Color(0.102, 0.102, 0.18)

var _breath_tween: Tween

func _ready():
	_apply_styles()
	btn_jugar.pressed.connect(_on_play_pressed)
	_start_breath_animation()
	Economia.recursos_actualizados.connect(_refresh_data)

func on_enter() -> void:
	_refresh_data()

func _refresh_data() -> void:
	lbl_gold.text = _format_number(Economia.ecos)
	lbl_frag.text = _format_number(Economia.fragmentos)
	lbl_plat.text = "0"  # TODO: añadir moneda platino cuando esté implementada

	var max_asc = Economia.numero_ascension
	lbl_ascension.text  = _format_number(max_asc)
	lbl_partidas.text   = "0"       # TODO: contador de partidas
	lbl_commanders.text = "0"       # TODO: contador de commanders eliminados

	var tier = _get_tier(max_asc)
	lbl_tier_name.text = TIER_NAMES.get(tier, "I — Void Initiate")
	_update_tier_dots(tier)

func _get_tier(max_asc: int) -> int:
	var tier = 1
	for i in TIER_THRESHOLDS.size():
		if max_asc >= TIER_THRESHOLDS[i]:
			tier = i + 1
	return clamp(tier, 1, 3)

func _update_tier_dots(tier: int) -> void:
	for i in dots.size():
		dots[i].color = COLOR_CIAN if i < tier else COLOR_DOT_OFF

# ── Animación de respiración del núcleo ───────────────────────────────────
func _start_breath_animation() -> void:
	if _breath_tween:
		_breath_tween.kill()
	
	_breath_tween = create_tween()
	_breath_tween.set_loops()
	_breath_tween.set_ease(Tween.EASE_IN_OUT)
	_breath_tween.set_trans(Tween.TRANS_SINE)
	
	# Inhalar: escala 1.0 → 1.08
	_breath_tween.tween_property(core_inner, "scale", Vector2(1.08, 1.08), 1.8)
	# Exhalar: escala 1.08 → 1.0
	_breath_tween.tween_property(core_inner, "scale", Vector2(1.0, 1.0), 1.8)
	
	# El outer respira más suave y con delay
	var tween_outer = create_tween()
	tween_outer.set_loops()
	tween_outer.set_ease(Tween.EASE_IN_OUT)
	tween_outer.set_trans(Tween.TRANS_SINE)
	tween_outer.tween_interval(0.4)
	tween_outer.tween_property(core_outer, "scale", Vector2(1.04, 1.04), 1.8)
	tween_outer.tween_property(core_outer, "scale", Vector2(1.0, 1.0), 1.8)

# ── Estilos ────────────────────────────────────────────────────────────────
func _apply_styles() -> void:
	# Estilo botón JUGAR
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.039, 0.165, 0.369)
	btn_style.border_color = Color(0.102, 0.416, 1.0)
	btn_style.set_border_width_all(1)
	btn_style.corner_radius_top_left = 14
	btn_style.corner_radius_top_right = 14
	btn_style.corner_radius_bottom_left = 14
	btn_style.corner_radius_bottom_right = 14
	btn_jugar.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.059, 0.22, 0.47)
	btn_jugar.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.02, 0.1, 0.25)
	btn_jugar.add_theme_stylebox_override("pressed", btn_pressed)
	
	# Estilos badges de monedas
	for badge in [$VBox/CoinsBar/GoldBadge, $VBox/CoinsBar/FragBadge, $VBox/CoinsBar/PlatBadge]:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.067, 0.067, 0.125)
		s.border_color = Color(0.118, 0.118, 0.22)
		s.set_border_width_all(1)
		s.corner_radius_top_left = 20
		s.corner_radius_top_right = 20
		s.corner_radius_bottom_left = 20
		s.corner_radius_bottom_right = 20
		s.content_margin_left = 10
		s.content_margin_right = 10
		s.content_margin_top = 5
		s.content_margin_bottom = 5
		badge.add_theme_stylebox_override("panel", s)
	
	# Estilos stat cards
	for card in [$VBox/StatsRow/StatAscension, $VBox/StatsRow/StatPartidas, $VBox/StatsRow/StatCommanders]:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.051, 0.051, 0.118)
		s.border_color = Color(0.102, 0.102, 0.188)
		s.set_border_width_all(1)
		s.corner_radius_top_left = 10
		s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = 10
		s.corner_radius_bottom_right = 10
		s.content_margin_left = 8
		s.content_margin_right = 8
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", s)
	
	# Anillos del núcleo redondeados
	for ring in [$VBox/NucleoCentro/Ring3, $VBox/NucleoCentro/Ring2, $VBox/NucleoCentro/Ring1,
				 $VBox/NucleoCentro/CoreOuter, $VBox/NucleoCentro/CoreInner]:
		# pivot al centro para la animación de escala
		ring.pivot_offset = ring.size / 2.0

# ── Helpers ────────────────────────────────────────────────────────────────
func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1000:
		return "%.1fk" % (n / 1000.0)
	return str(n)

func _on_play_pressed() -> void:
	play_pressed.emit()
	get_tree().change_scene_to_file("res://escenas/ui/LoadingScreen.tscn")
