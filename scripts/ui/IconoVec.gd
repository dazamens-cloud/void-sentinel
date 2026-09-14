class_name IconoVec
extends Control
# ============================================================
# ICONOS VECTORIALES — Void Sentinel
#
# Dibuja los iconos del menu por codigo en vez de depender de glifos de
# fuente. Motivo: ninguna de las fuentes del proyecto (Orbitron, Rajdhani)
# trae los simbolos geometricos que usaba el menu; se veian solo porque
# Windows presta un fallback. En Android ese fallback puede no existir y
# saldrian rotos, como ya pasaba con el emoji calavera del Home ("G80").
#
# Uso:
#   var ic := IconoVec.crear(IconoVec.Forma.RAYO, 30, MenuTheme.GOLD)
#   contenedor.add_child(ic)
# ============================================================

enum Forma {
	ROMBO,          # fragmentos
	ROMBO_PUNTO,    # ecos
	ROMBO_HUECO,    # gemas
	RAYO,           # energia / velocidad
	ESTRELLA,       # logros, mejoras gratis
	TRIANGULO,      # ascension, records
	PLAY,           # jugar, partidas
	CRUZ,           # muerte, enemigos destruidos
	MAS,            # recuperacion, curacion
	CORAZON,        # salud
	ESCUDO,         # escudo, defensa
	CIRCULO,        # alcance, radio
	CIRCULO_DOBLE,  # pulso
	DESTELLO,       # danio, critico
	CASA,           # inicio
	HEXAGONO,       # perfil
	FLECHA_CIRC,    # rebote
	PUNTOS,         # multidisparo
	PAUSA,          # boton de pausa
}

var forma: Forma = Forma.ROMBO
var color: Color = Color.WHITE
var grosor: float = 2.0


static func crear(f: Forma, tam: float, c: Color) -> IconoVec:
	var ic := IconoVec.new()
	ic.forma = f
	ic.color = c
	ic.custom_minimum_size = Vector2(tam, tam)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


func _draw() -> void:
	var c := size / 2.0
	var r: float = minf(size.x, size.y) * 0.42

	match forma:
		Forma.ROMBO:
			draw_colored_polygon(_rombo(c, r), color)
		Forma.ROMBO_PUNTO:
			draw_polyline(_rombo(c, r) + PackedVector2Array([_rombo(c, r)[0]]), color, grosor, true)
			draw_circle(c, r * 0.28, color)
		Forma.ROMBO_HUECO:
			draw_polyline(_rombo(c, r) + PackedVector2Array([_rombo(c, r)[0]]), color, grosor, true)
		Forma.RAYO:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(r * 0.30, -r),
				c + Vector2(-r * 0.55, r * 0.12),
				c + Vector2(-r * 0.05, r * 0.12),
				c + Vector2(-r * 0.30, r),
				c + Vector2(r * 0.55, -r * 0.15),
				c + Vector2(r * 0.05, -r * 0.15),
			]), color)
		Forma.ESTRELLA:
			draw_colored_polygon(_estrella(c, r, r * 0.42, 5), color)
		Forma.TRIANGULO:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.88, r * 0.6), c + Vector2(-r * 0.88, r * 0.6),
			]), color)
		Forma.PLAY:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.55, -r * 0.85), c + Vector2(r * 0.85, 0), c + Vector2(-r * 0.55, r * 0.85),
			]), color)
		Forma.CRUZ:
			var d := r * 0.72
			draw_line(c + Vector2(-d, -d), c + Vector2(d, d), color, grosor, true)
			draw_line(c + Vector2(d, -d), c + Vector2(-d, d), color, grosor, true)
		Forma.MAS:
			draw_line(c + Vector2(0, -r), c + Vector2(0, r), color, grosor, true)
			draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), color, grosor, true)
		Forma.CORAZON:
			draw_colored_polygon(_corazon(c, r), color)
		Forma.ESCUDO:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.55),
				c + Vector2(r * 0.8, r * 0.25), c + Vector2(0, r),
				c + Vector2(-r * 0.8, r * 0.25), c + Vector2(-r * 0.8, -r * 0.55),
			]), color)
		Forma.CIRCULO:
			draw_arc(c, r, 0, TAU, 40, color, grosor, true)
		Forma.CIRCULO_DOBLE:
			draw_arc(c, r, 0, TAU, 40, color, grosor, true)
			draw_circle(c, r * 0.38, color)
		Forma.DESTELLO:
			# Cuatro puntas curvadas hacia dentro: el "brillo" del mockup.
			var pts := PackedVector2Array()
			for i in range(4):
				var a := TAU * float(i) / 4.0 - PI / 2.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
				var a2 := a + TAU / 8.0
				pts.append(c + Vector2(cos(a2), sin(a2)) * r * 0.24)
			draw_colored_polygon(pts, color)
		Forma.CASA:
			# Tejado bajo y cuerpo ancho: con el tejado alto parecia una flecha.
			var alero := -r * 0.15
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r, alero), c + Vector2(-r, alero),
			]), color)
			draw_rect(Rect2(c + Vector2(-r * 0.66, alero), Vector2(r * 1.32, r * 0.95)), color)
		Forma.HEXAGONO:
			var hex := PackedVector2Array()
			for i in range(6):
				var a := TAU * float(i) / 6.0 - PI / 2.0
				hex.append(c + Vector2(cos(a), sin(a)) * r)
			hex.append(hex[0])
			draw_polyline(hex, color, grosor, true)
		Forma.FLECHA_CIRC:
			draw_arc(c, r * 0.85, PI * 0.35, PI * 1.9, 32, color, grosor, true)
			var p := c + Vector2(cos(PI * 0.35), sin(PI * 0.35)) * r * 0.85
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(-r * 0.3, -r * 0.12), p + Vector2(r * 0.18, -r * 0.05),
				p + Vector2(-r * 0.05, r * 0.32),
			]), color)
		Forma.PUNTOS:
			for dx in [-0.45, 0.45]:
				for dy in [-0.45, 0.45]:
					draw_circle(c + Vector2(r * dx, r * dy), r * 0.2, color)
		Forma.PAUSA:
			var ancho := r * 0.34
			draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.8), Vector2(ancho, r * 1.6)), color)
			draw_rect(Rect2(c + Vector2(r * 0.28, -r * 0.8), Vector2(ancho, r * 1.6)), color)


func _rombo(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r * 0.78, 0),
		c + Vector2(0, r), c + Vector2(-r * 0.78, 0),
	])


func _estrella(c: Vector2, r_ext: float, r_int: float, puntas: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(puntas * 2):
		var a := TAU * float(i) / float(puntas * 2) - PI / 2.0
		var rad := r_ext if i % 2 == 0 else r_int
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	return pts


func _corazon(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(24):
		var t := TAU * float(i) / 24.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * (r / 17.0))
	return pts
