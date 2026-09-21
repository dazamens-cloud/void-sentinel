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
	var color := Color(0.0, 0.9, 0.5, 1.0)
	text = Formato.abreviar(valor)
	add_theme_color_override("font_color", color)
	# El rayo va dibujado: "⚡" (U+26A1) sale como hueco en Android.
	_poner_icono(IconoVec.Forma.RAYO, color)

func set_ecos(valor: int) -> void:
	var color := Color(1.0, 0.8, 0.2, 1.0)
	text = Formato.abreviar(valor)
	add_theme_color_override("font_color", color)
	_poner_icono(IconoVec.Forma.ROMBO_PUNTO, color)

# Icono a la izquierda de la cifra, fuera del rect de la etiqueta.
func _poner_icono(forma: IconoVec.Forma, color: Color) -> void:
	for hijo in get_children():
		if hijo is IconoVec:
			hijo.queue_free()
	var ic := IconoVec.crear(forma, 18, color)
	ic.position = Vector2(-20, 4)
	add_child(ic)

func set_valor(valor: float, tipo: String = "energia") -> void:
	if tipo == "energia":
		set_energia(int(valor))
	elif tipo == "ecos":
		set_ecos(int(valor))
	else:
		text = Formato.abreviar(valor)
		add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
