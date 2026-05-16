extends Label
# ═══════════════════════════════════════════════════
# TEXTO FLOTANTE — Muestra recompensas al matar enemigos
# ═══════════════════════════════════════════════════

func _ready() -> void:
	$Timer.timeout.connect(queue_free)
	$Timer.start()
	
	# Animación: sube y se desvanece
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.8)

func set_energia(valor: int) -> void:
	text = "⚡ %d" % valor
	add_theme_color_override("font_color", Color(0.0, 0.9, 0.5, 1.0))  # Verde

func set_ecos(valor: int) -> void:
	text = "◉ %d" % valor
	add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Dorado

func set_valor(valor: float, tipo: String) -> void:
	match tipo:
		"dano":
			text = "-%d" % int(valor)
		_:
			text = "%d" % int(valor)
