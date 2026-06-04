class_name SafeArea
extends RefCounted
# ═══════════════════════════════════════════════════
# SAFE AREA — Void Sentinel
# Convierte el "área segura" física del dispositivo (zona libre de notch arriba
# y de la barra de navegación del sistema abajo) a márgenes en coordenadas del
# viewport del juego (720×1280 con stretch).
#
# En PC / editor no hay notch ni barras → todos los márgenes salen 0, así que
# la UI usa sus valores por defecto.
#
# Uso:
#   var m := SafeArea.margenes(get_viewport().get_visible_rect().size)
#   panel.offset_top = m["top"]; panel.offset_bottom = -m["bottom"]
# ═══════════════════════════════════════════════════

static func margenes(vp_size: Vector2) -> Dictionary:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win: Vector2i = DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	# Escala física → viewport (la ventana puede no coincidir con 720×1280).
	var sx: float = vp_size.x / float(win.x)
	var sy: float = vp_size.y / float(win.y)
	return {
		"top":    float(safe.position.y) * sy,
		"bottom": float(win.y - (safe.position.y + safe.size.y)) * sy,
		"left":   float(safe.position.x) * sx,
		"right":  float(win.x - (safe.position.x + safe.size.x)) * sx,
	}
