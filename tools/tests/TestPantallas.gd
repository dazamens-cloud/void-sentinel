extends Node
# ═══════════════════════════════════════════════════
# PRUEBAS DE PANTALLAS — Void Sentinel
#
# Monta cada pantalla del menú (construidas por código, sin .tscn) y las
# navega, para detectar las que revientan al abrirse. No juzga lo visual:
# comprueba que se instancian, construyen hijos y sobreviven a la navegación.
#
#   godot --path . --headless tools/tests/TestPantallas.tscn
# ═══════════════════════════════════════════════════

var _fallos: int = 0
var _pasados: int = 0

const PANTALLAS := [
	"res://scripts/ui/HomeScreen.gd",
	"res://scripts/ui/Nexoscreen.gd",
	"res://scripts/ui/Forjascreen.gd",
	"res://scripts/ui/PerfilScreen.gd",
	"res://scripts/ui/TiendaScreen.gd",
	"res://scripts/ui/LabScreen.gd",
	"res://scripts/ui/MisionesScreen.gd",
	"res://scripts/ui/NavBar.gd",
]


func _ready() -> void:
	print("═══ PRUEBAS DE PANTALLAS ═══\n")

	print("── Cada pantalla por separado")
	for ruta in PANTALLAS:
		await _probar_pantalla(ruta)

	print("\n── MainMenu completo y navegación")
	await _probar_menu_completo()

	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


func _probar_pantalla(ruta: String) -> void:
	var nombre: String = ruta.get_file().get_basename()
	var script: Script = load(ruta)
	if script == null:
		_ok(false, "%s: el script carga" % nombre)
		return

	var nodo := Control.new()
	nodo.set_script(script)
	add_child(nodo)
	await get_tree().process_frame
	await get_tree().process_frame

	var vivo: bool = is_instance_valid(nodo) and nodo.is_inside_tree()
	_ok(vivo, "%s: se monta sin morir" % nombre)
	if vivo:
		_ok(nodo.get_child_count() > 0,
			"%s: construye su UI (%d hijos)" % [nombre, nodo.get_child_count()])

	if is_instance_valid(nodo):
		nodo.queue_free()
	await get_tree().process_frame


func _probar_menu_completo() -> void:
	var menu := Control.new()
	menu.set_script(load("res://scripts/ui/Mainmenu.gd"))
	add_child(menu)
	for i in 4:
		await get_tree().process_frame

	_ok(is_instance_valid(menu) and menu.is_inside_tree(), "MainMenu se monta")
	if not is_instance_valid(menu):
		return

	var screens: Dictionary = menu.get("screens")
	_ok(screens != null and screens.size() > 0,
		"MainMenu construye sus pantallas (%d)" % (screens.size() if screens else 0))

	# Navegar por todas, ida y vuelta, buscando la que muera al reabrirse.
	_ok(menu.has_method("navigate"), "MainMenu expone navigate()")
	if not menu.has_method("navigate") or not screens:
		return
	var ids: Array = screens.keys()
	for vuelta in 2:
		for id in ids:
			menu.navigate(id)
			await get_tree().process_frame
			var ok: bool = is_instance_valid(menu) and is_instance_valid(screens[id])
			_ok(ok, "navegar a '%s' (vuelta %d)" % [id, vuelta + 1])
			if not ok:
				return
	# Solo la pantalla destino queda visible.
	menu.navigate("home")
	await get_tree().process_frame
	var visibles: Array = []
	for id in ids:
		if screens[id].visible:
			visibles.append(id)
	_ok(visibles == ["home"],
		"tras navegar a home solo home queda visible (visibles: %s)" % str(visibles))
	# Una pantalla inexistente no debe tumbar el menú.
	menu.navigate("no_existe")
	await get_tree().process_frame
	_ok(is_instance_valid(menu), "navegar a una pantalla inexistente no revienta")

	menu.queue_free()
	await get_tree().process_frame


func _ok(cond: bool, desc: String) -> void:
	if cond:
		_pasados += 1
		print("   ✓ ", desc)
	else:
		_fallos += 1
		print("   ✗ FALLO: ", desc)
