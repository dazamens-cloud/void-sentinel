extends Node
# ═══════════════════════════════════════════════════
# AUDIO MANAGER — SFX y música de Void Sentinel (autoload).
#
# Carga PEREZOSA desde res://audio/. Si un archivo no existe, ese sonido
# simplemente no suena (no crashea). Así el sistema queda cableado aunque
# todavía no hayas metido los audios: en cuanto sueltes los .ogg con el
# nombre correcto en res://audio/sfx/ o /music/, cobran vida solos.
#
# Uso:
#   AudioManager.sfx("muerte")
#   AudioManager.musica("combate")   # loop; ignora si ya suena esa
#
# Nombres de archivo esperados (cualquiera de .ogg/.wav/.mp3):
#   sfx/   disparo, muerte, critico, dano_nexus, compra, game_over
#   music/ menu, combate
# ═══════════════════════════════════════════════════

const SFX_DIR: String = "res://audio/sfx/"
const MUSIC_DIR: String = "res://audio/music/"

const SFX_NOMBRES: Array = ["disparo", "muerte", "critico", "dano_nexus", "compra", "game_over"]
const MUSICA_NOMBRES: Array = ["menu", "combate"]

const NUM_CANALES: int = 10

var sfx_volumen_db: float = 0.0
var musica_volumen_db: float = -8.0
var silencio: bool = false

var _pool: Array[AudioStreamPlayer] = []
var _idx: int = 0
var _cache: Dictionary = {}          # nombre -> AudioStream (o null si no existe)
var _player_musica: AudioStreamPlayer
var _musica_actual: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in NUM_CANALES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_player_musica = AudioStreamPlayer.new()
	add_child(_player_musica)


func _cargar(dir: String, nombre: String) -> AudioStream:
	if _cache.has(nombre):
		return _cache[nombre]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav", ".mp3"]:
		var path: String = dir + nombre + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[nombre] = stream
	return stream


# Reproduce un SFX en un canal libre del pool. Varía el tono levemente para
# que repetirlo (disparos, muertes) no suene monótono.
func sfx(nombre: String, variar_tono: bool = true) -> void:
	if silencio:
		return
	var stream := _cargar(SFX_DIR, nombre)
	if stream == null:
		return
	var p := _pool[_idx]
	_idx = (_idx + 1) % NUM_CANALES
	p.stream = stream
	p.volume_db = sfx_volumen_db
	p.pitch_scale = randf_range(0.95, 1.06) if variar_tono else 1.0
	p.play()


# Cambia la música de fondo (loop). No reinicia si ya suena la misma.
func musica(nombre: String) -> void:
	if _musica_actual == nombre:
		return
	var stream := _cargar(MUSIC_DIR, nombre)
	_musica_actual = nombre
	if stream == null:
		_player_musica.stop()
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_player_musica.stream = stream
	_player_musica.volume_db = musica_volumen_db
	_player_musica.play()


func parar_musica() -> void:
	_musica_actual = ""
	_player_musica.stop()
