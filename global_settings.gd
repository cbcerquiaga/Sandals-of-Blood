extends Node
class_name Settings_Global #inverted so that the variable GlobalSettings comes up first in autocomplete

enum FieldType { ROAD, CULDESAC, HORSESHOE }
#current game
var regular_season: bool = true #determines the type of overtime. In regular season, games can end in ties, while in playoffs someone must win
var field_type: FieldType = FieldType.ROAD #impacts a bunch of stuff. TODO: make more kinds of fields
var recording: Array #array of images, used to make a replay of the game for export
var match_log: Array #array of strings, used to create the game log for export
#display
var brightness: float = 55 #screen brightness
var game_speed: float = 0.35 #speed of gameplay
var resolution: Vector2
var fullscreen: bool = false #true = fullscreen false = windowed
var colorblind: bool = false #replaces green textures with teal ones
#control
var keyboard_control_scheme: String #which control scheme is used for keyboard
var controller_control_scheme: String #which control scheme is used for controller
var mouse_sensitivity: float = 1 #how much the game reacts to mouse movements
var controller_sensitivity: float = 1 #how much the game reacts to controller analog stick inputs
var semiAuto: bool = false #if true, the AI will move the human keeper around and the player just worries about aiming
#gameplay
var target_score: int = 7 #(usually) max score a team can get in the game before the game ends
var pitch_limit: int  = 20#(usually) max number of pitches thrown by both teams before a game ends
var play_time: int = 30 #maximum length on seconds of a single play
var human_buff: int #how much to buff all human player attributes
var cpu_buff: int #how much to buff all cpu player attributes
var human_always_pitch: bool = false #if on, human team always gets to pitch
var special_pitch_frequency: float = 1 #increases or decreases groove collection
var injury_frequency: float = 1 #how often unjuries occur
var severe_injuries: bool = true #if players can get crippled, paralyzed, or killed in game
#audio
var tracks: Dictionary #"title": bool format, whether or not particular songs play in the menu
var master_vol: float
var music_vol: float #volue of menu music
var sfx_vol: float #sound effects of players in the game- footsteps, contact with ball, player voices
var crowd_vol: float #cheering, chanting, bands, announcers
var stereo: bool = true #whether the same sound comes out of every speaker or it is different from the left and right
#career
var survival_difficulty: int #code for how tough it is to survive the wasteland
var travel_danger: int #code for how dangerous it is to travel
var signing_difficulty: int #how tough it is to convince players to sign with you, how much they are willing to haggle, how likely other teams match offer sheets
var management_difficulty: int #how much players will try to leave, cause problems; how much xp players get, quality of auto-generated players, cost of improvements, difficulty of managing relationships with players, other teams, gangs, and fans
var poaching: bool #if other teams will deliberately try to sign your players when you have no money or you're otherwise vulnerable

#profile
var save_file: String #path to save file
var coach: Coach #player character
var franchise: Franchise #team, arena, staff, inventory, relationships
var world_state: Dictionary #leagues, teams, 
var history #player, team, league stats

func _ready():
	if resolution == Vector2.ZERO:
		resolution = Vector2(1920, 1080)

func transfer_settings(other_settings: Settings_Global):
	brightness = other_settings.brightness
	game_speed = other_settings.game_speed
	resolution = other_settings.resolution
	fullscreen = other_settings.fullscreen
	keyboard_control_scheme = other_settings.keyboard_control_scheme
	controller_control_scheme = other_settings.controller_control_scheme
	target_score = other_settings.target_score
	pitch_limit = other_settings.pitch_limit
	play_time = other_settings.play_time
	human_buff = other_settings.human_buff
	cpu_buff = other_settings.cpu_buff
	human_always_pitch = other_settings.human_always_pitch
	special_pitch_frequency = other_settings.special_pitch_frequency
	injury_frequency = other_settings.injury_frequency
	severe_injuries = other_settings.severe_injuries
	tracks =other_settings.tracks
	master_vol = other_settings.master_vol
	music_vol = other_settings.music_vol
	sfx_vol = other_settings.music_vol
	crowd_vol = other_settings.crowd_vol
	stereo = other_settings.stereo
	survival_difficulty = other_settings.survival_difficulty
	travel_danger = other_settings.travel_danger
	signing_difficulty = other_settings.signing_difficulty
	management_difficulty = other_settings.management_difficulty
	poaching = other_settings.poaching
	
func clear_recordings():
	match_log.clear()
	recording.clear()

func record_event(value: String):
	match_log.append(value)

func export_recording(name: String):
	if recording.is_empty():
		OS.alert("No frames recorded.", "Failed")
		return
	var save_place = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var file_path = save_place.path_join(name)
	# 8 centiseconds per frame (~12fps). Adjust to match your record_frame() call rate.
	# max_width caps output resolution; frame_skip=1 exports every captured frame.
	var gif_bytes = _encode_gif(recording, 8, 480, 1)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_buffer(gif_bytes)
		file.close()
		OS.alert(name + " has been saved to your downloads folder.", "Success")
	else:
		OS.alert("Failed to save the GIF file.", "Failed")

func export_game_log(name: String):
	var full_text = ""
	for element in match_log:
		full_text = full_text + element + "\n"
	var save_place = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var file_path = save_place.path_join(name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(full_text)
		file.close()
		OS.alert(name + " has been saved to your downloads folder.", "Success")
	else:
		OS.alert("Failed to save the log file.", "Failed")

func _encode_gif(frames: Array, delay_cs: int, max_width: int = 480, frame_skip: int = 1) -> PackedByteArray:
	if frames.is_empty():
		return PackedByteArray()
	var src_w: int = frames[0].get_width()
	var src_h: int = frames[0].get_height()
	var scale: float = min(1.0, float(max_width) / float(src_w))
	var out_w: int = max(1, int(src_w * scale))
	var out_h: int = max(1, int(src_h * scale))
	var palette = PackedByteArray()
	for r in range(8):
		for g in range(8):
			for b in range(4):
				palette.append(int(r * 255.0 / 7.0 + 0.5))
				palette.append(int(g * 255.0 / 7.0 + 0.5))
				palette.append(int(b * 255.0 / 3.0 + 0.5))
	var buf = PackedByteArray()
	buf.append_array("GIF89a".to_ascii_buffer())
	_gif_u16(buf, out_w)
	_gif_u16(buf, out_h)
	buf.append(0xF7)  # GCT present, 256 colours
	buf.append(0)     # background colour index
	buf.append(0)     # pixel aspect ratio
	buf.append_array(palette)
	buf.append(0x21); buf.append(0xFF); buf.append(11)
	buf.append_array("NETSCAPE2.0".to_ascii_buffer())
	buf.append(3); buf.append(1)
	_gif_u16(buf, 0)  # 0 = infinite loops
	buf.append(0)

	var frame_step = max(1, frame_skip)
	var fi = 0
	while fi < frames.size():
		var img: Image = frames[fi].duplicate()
		if img.get_width() != out_w or img.get_height() != out_h:
			img.resize(out_w, out_h, Image.INTERPOLATE_BILINEAR)
		img.convert(Image.FORMAT_RGB8)

		var raw_data = img.get_data()
		var pixel_count = out_w * out_h
		var indices = PackedByteArray()
		indices.resize(pixel_count)
		for idx in range(pixel_count):
			var ri: int = (int(raw_data[idx * 3])     * 7 + 127) / 255
			var gi: int = (int(raw_data[idx * 3 + 1]) * 7 + 127) / 255
			var bi: int = (int(raw_data[idx * 3 + 2]) * 3 + 127) / 255
			indices[idx] = ri * 32 + gi * 4 + bi

		buf.append(0x21); buf.append(0xF9); buf.append(4)
		buf.append(0x00)
		_gif_u16(buf, delay_cs)
		buf.append(0); buf.append(0)
		buf.append(0x2C)
		_gif_u16(buf, 0); _gif_u16(buf, 0)
		_gif_u16(buf, out_w); _gif_u16(buf, out_h)
		buf.append(0x00)
		buf.append(8)  # min code size
		var compressed = _gif_lzw_compress(indices, 8)
		var ci = 0
		while ci < compressed.size():
			var chunk_len = min(255, compressed.size() - ci)
			buf.append(chunk_len)
			buf.append_array(compressed.slice(ci, ci + chunk_len))
			ci += chunk_len
		buf.append(0)

		fi += frame_step

	buf.append(0x3B)  # GIF trailer
	return buf


func _gif_lzw_compress(indices: PackedByteArray, min_code_size: int) -> PackedByteArray:
	var clear_code: int = 1 << min_code_size
	var eoi_code: int   = clear_code + 1
	var next_code: int  = eoi_code + 1
	var code_size: int  = min_code_size + 1
	var code_table = {}
	var output = PackedByteArray()
	var bit_buf: int = 0
	var bit_len: int = 0

	bit_buf |= clear_code << bit_len
	bit_len += code_size
	while bit_len >= 8:
		output.append(bit_buf & 0xFF); bit_buf >>= 8; bit_len -= 8

	if indices.is_empty():
		bit_buf |= eoi_code << bit_len; bit_len += code_size
		while bit_len >= 8:
			output.append(bit_buf & 0xFF); bit_buf >>= 8; bit_len -= 8
		if bit_len > 0: output.append(bit_buf & 0xFF)
		return output

	var prefix: int = int(indices[0])
	for i in range(1, indices.size()):
		var suffix: int = int(indices[i])
		var key: int    = prefix * 256 + suffix
		if code_table.has(key):
			prefix = code_table[key]
		else:
			bit_buf |= prefix << bit_len; bit_len += code_size
			while bit_len >= 8:
				output.append(bit_buf & 0xFF); bit_buf >>= 8; bit_len -= 8
			if next_code <= 4095:
				code_table[key] = next_code
				next_code += 1
				if code_size < 12 and next_code == (1 << code_size):
					code_size += 1
			prefix = suffix

	bit_buf |= prefix << bit_len; bit_len += code_size
	while bit_len >= 8:
		output.append(bit_buf & 0xFF); bit_buf >>= 8; bit_len -= 8
	bit_buf |= eoi_code << bit_len; bit_len += code_size
	while bit_len >= 8:
		output.append(bit_buf & 0xFF); bit_buf >>= 8; bit_len -= 8
	if bit_len > 0:
		output.append(bit_buf & 0xFF)
	return output


func _gif_u16(buf: PackedByteArray, val: int) -> void:
	buf.append(val & 0xFF)
	buf.append((val >> 8) & 0xFF)
