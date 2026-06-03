extends Node2D
# ═══════════════════════════════════════════════════
# MUNDO — Void Sentinel
# ═══════════════════════════════════════════════════

@onready var camara: Camera2D = $Camera2D
@onready var nucleo: Node2D = $Nexus
@onready var gestor_oleadas: Node = $AscensionManager
@onready var hud: CanvasLayer = $Interfaz
@onready var dron: Node2D = $Dron

# ═══════════════════════════════════════════════════
func _ready() -> void:
	# ✅ Resetear autoloads SIEMPRE al entrar a la escena
	NexusStats.reiniciar_partida()
	Economia.iniciar_partida()
	MejoraManager.reiniciar_mejoras()

	# 🧪 Modo prueba: si se lanzó desde "JUGAR PRUEBA", inyecta estado avanzado.
	# ▶️ Reanudar: restaura el checkpoint guardado al salir al menú.
	# (else) Partida nueva: descarta cualquier run guardada previa.
	if ModoPrueba.activo:
		ModoPrueba.aplicar()
	elif ReanudarPartida.debe_reanudar:
		ReanudarPartida.aplicar()
	else:
		ReanudarPartida.borrar()

	_conectar_economia()
	_conectar_gestor_oleadas()
	_conectar_nucleo()
	_conectar_dron()
	_configurar_camara()

	# 🎵 Música de combate (loop). Si no hay archivo, no suena.
	AudioManager.musica("combate")

# 🧪 Atajo de prueba: tecla C invoca al Commander (solo en partidas de prueba).
func _unhandled_input(event: InputEvent) -> void:
	if not ModoPrueba.partida_es_prueba:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		if is_instance_valid(gestor_oleadas) and gestor_oleadas.has_method("forzar_commander"):
			gestor_oleadas.forzar_commander()

# ═══════════════════════════════════════════════════
func _conectar_economia() -> void:
	if Economia.has_signal("juego_terminado"):
		Economia.juego_terminado.connect(_on_juego_terminado)
		print("🌍 Mundo: Conectada señal juego_terminado de Economia")

func _conectar_gestor_oleadas() -> void:
	if not is_instance_valid(gestor_oleadas): return
	if gestor_oleadas.has_signal("ascension_iniciada"):
		gestor_oleadas.ascension_iniciada.connect(_on_ascension_iniciada)
	if gestor_oleadas.has_signal("ascension_completada"):
		gestor_oleadas.ascension_completada.connect(_on_ascension_completada)
	if gestor_oleadas.has_signal("pausa_entre_ascensiones"):
		gestor_oleadas.pausa_entre_ascensiones.connect(_on_pausa_entre_ascensiones)
	print("🌍 Mundo: Conectadas señales de AscensionManager")

func _conectar_nucleo() -> void:
	if not is_instance_valid(nucleo): return
	print("🌍 Mundo: Nexus encontrado")

func _conectar_dron() -> void:
	if not is_instance_valid(dron): return
	print("🌍 Mundo: Dron encontrado")

func _configurar_camara() -> void:
	if not is_instance_valid(camara): return
	if is_instance_valid(nucleo):
		camara.global_position = nucleo.global_position
	camara.make_current()
	# 🎥 Registrar la cámara en FX para el screen shake de esta partida.
	FX.registrar_camara(camara)

# ═══════════════════════════════════════════════════
# HANDLERS
# ═══════════════════════════════════════════════════
func _on_ascension_iniciada(numero: int) -> void:
	print("🌍 Mundo: Ascensión ", numero, " iniciada")

func _on_ascension_completada(numero: int) -> void:
	print("🌍 Mundo: Ascensión ", numero, " completada")

func _on_pausa_entre_ascensiones(segundos: float) -> void:
	print("🌍 Mundo: Pausa de ", segundos, " segundos")

func _on_juego_terminado(causa: String) -> void:
	print("🌍 Mundo: JUEGO TERMINADO - ", causa)
	get_tree().paused = true
	# ✅ Siempre mostrar Game Over — el hud siempre existe
	if hud and hud.has_method("mostrar_game_over"):
		hud.mostrar_game_over(causa)
