extends Label
# ═══════════════════════════════════════════════════
# TEXTO FLOTANTE — Muestra recompensas al matar enemigos
# ═══════════════════════════════════════════════════

func _ready() -> void:
	$Timer.timeout.connect(queue_free)
	$Timer.start()
	
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.8)

func set_energia(valor: int) -> void:
	text = "⚡ %s" % Formato.abreviar(valor)
	add_theme_color_override("font_color", Color(0.0, 0.9, 0.5, 1.0))

func set_ecos(valor: int) -> void:
	text = "◉ %s" % Formato.abreviar(valor)
	add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))

func set_valor(valor: float, tipo: String = "energia") -> void:
	if tipo == "energia":
		set_energia(int(valor))
	elif tipo == "ecos":
		set_ecos(int(valor))
	else:
		text = Formato.abreviar(valor)
		add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
