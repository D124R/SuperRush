extends Node

const MUSIC_PATH := "res://assets/audio/super_rush_theme.ogg"
const MUSIC_VOLUME_DB := -9.0

var music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var music := load(MUSIC_PATH) as AudioStreamOggVorbis
	if music == null:
		push_error("A trilha do jogo nao foi carregada: %s" % MUSIC_PATH)
		return

	var looped_music := music.duplicate() as AudioStreamOggVorbis
	looped_music.loop = true
	looped_music.loop_offset = 0.0

	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.stream = looped_music
	music_player.volume_db = MUSIC_VOLUME_DB
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.play()


func pause_music() -> void:
	if music_player != null:
		music_player.stream_paused = true


func resume_music() -> void:
	if music_player != null:
		music_player.stream_paused = false