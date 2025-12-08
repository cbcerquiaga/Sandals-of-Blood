extends Node
class_name CharacterImporter

# Fast lookup tables for validation
const VALID_POSITIONS = ["LG", "RG", "LF", "RF", "K", "P"]
const VALID_GENDERS = ["m", "f", "i"]
const VALID_DAY_JOBS = ["none", "farm", "blue", "white", "school", "rich", "gang"]

var free_agents: Dictionary = {} # Key: character name, Value: Character
var franchises: Dictionary = {} # Key: franchise_id, Value: Franchise

signal import_progress(current: int, total: int)
signal import_complete(total_imported: int, free_agents: int, franchised: int)

func import_from_csv(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + file_path)
		return {"success": false, "error": "File not found"}
	
	var headers = file.get_csv_line()
	var header_map = _build_header_map(headers)
	
	var characters_imported = 0
	var free_agent_count = 0
	var franchised_count = 0
	var line_number = 1
	
	# Batch processing for better performance
	var batch_size = 100
	var batch = []
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		line_number += 1
		
		# Skip empty lines
		if line.size() <= 1 or (line.size() == 1 and line[0].strip_edges() == ""):
			continue
		
		batch.append({"line": line, "number": line_number})
		
		if batch.size() >= batch_size:
			var result = _process_batch(batch, header_map)
			characters_imported += result.imported
			free_agent_count += result.free_agents
			franchised_count += result.franchised
			
			emit_signal("import_progress", characters_imported, -1)
			batch.clear()
	
	# Process remaining batch
	if batch.size() > 0:
		var result = _process_batch(batch, header_map)
		characters_imported += result.imported
		free_agent_count += result.free_agents
		franchised_count += result.franchised
	
	file.close()
	
	emit_signal("import_complete", characters_imported, free_agent_count, franchised_count)
	
	return {
		"success": true,
		"total_imported": characters_imported,
		"free_agents": free_agent_count,
		"franchised": franchised_count
	}

func _build_header_map(headers: PackedStringArray) -> Dictionary:
	var map = {}
	for i in range(headers.size()):
		map[headers[i].strip_edges().to_lower()] = i
	return map

func _process_batch(batch: Array, header_map: Dictionary) -> Dictionary:
	var imported = 0
	var free_agents_in_batch = 0
	var franchised_in_batch = 0
	
	for entry in batch:
		var character = _parse_character_from_line(entry.line, header_map, entry.number)
		if character:
			var placed = _place_character(character)
			imported += 1
			if placed == "free_agent":
				free_agents_in_batch += 1
			else:
				franchised_in_batch += 1
	
	return {
		"imported": imported,
		"free_agents": free_agents_in_batch,
		"franchised": franchised_in_batch
	}

func _parse_character_from_line(line: PackedStringArray, header_map: Dictionary, line_num: int) -> Character:
	var character = Character.new()
	character.player = Player.new()
	character.contract = Contract.new()
	
	# Helper function to safely get values
	var get_val = func(key: String, default = ""):
		var idx = header_map.get(key, -1)
		if idx >= 0 and idx < line.size():
			return line[idx].strip_edges()
		return default
	
	var get_int = func(key: String, default: int = 0):
		var val = get_val.call(key)
		return int(val) if val != "" else default
	
	var get_float = func(key: String, default: float = 0.0):
		var val = get_val.call(key)
		return float(val) if val != "" else default
	
	var get_bool = func(key: String, default: bool = false):
		var val = get_val.call(key).to_lower()
		if val in ["true", "1", "yes"]: return true
		if val in ["false", "0", "no"]: return false
		return default
	
	# Bio data
	character.player.bio.first_name = get_val.call("first_name", "Unknown")
	character.player.bio.last_name = get_val.call("last_name", "Player")
	character.player.bio.nickname = get_val.call("nickname", "")
	character.player.bio.hometown = get_val.call("hometown", "Unknown")
	character.player.bio.leftHanded = get_bool.call("left_handed", false)
	character.player.bio.feet = get_int.call("feet", 6)
	character.player.bio.inches = get_int.call("inches", 0)
	character.player.bio.pounds = get_int.call("pounds", 180)
	character.player.bio.years = get_int.call("years", 25)
	
	# Attributes
	var attrs = character.player.attributes
	attrs.speedRating = get_int.call("speed_rating", 75)
	attrs.speed = attrs.speedRating + 35.0
	attrs.sprint_speed = (attrs.speedRating - 5) * 2.0
	attrs.blocking = get_int.call("blocking", 50)
	attrs.positioning = get_int.call("positioning", 50)
	attrs.aggression = get_int.call("aggression", 50)
	attrs.reactions = get_int.call("reactions", 50)
	attrs.durability = get_int.call("durability", 50)
	attrs.power = get_int.call("power", 50)
	attrs.throwing = get_int.call("throwing", 50)
	attrs.endurance = get_int.call("endurance", 50)
	attrs.accuracy = get_int.call("accuracy", 50)
	attrs.balance = get_int.call("balance", 50)
	attrs.focus = get_int.call("focus", 50)
	attrs.shooting = get_int.call("shooting", 50)
	attrs.toughness = get_int.call("toughness", 50)
	attrs.confidence = get_int.call("confidence", 50)
	attrs.agility = get_int.call("agility", 50)
	attrs.faceoffs = get_int.call("faceoffs", 50)
	attrs.discipline = get_int.call("discipline", 80)
	
	# Positions
	var positions_str = get_val.call("playable_positions", "")
	if positions_str != "":
		character.player.playable_positions = positions_str.split(",")
		for i in range(character.player.playable_positions.size()):
			character.player.playable_positions[i] = character.player.playable_positions[i].strip_edges()
	
	character.player.preferred_position = get_val.call("preferred_position", "")
	character.player.declared_pitcher = get_bool.call("declared_pitcher", false)
	
	# Special pitches
	var pitch_names = get_val.call("special_pitches", "")
	if pitch_names != "":
		var names = pitch_names.split(",")
		character.player.special_pitch_names.clear()
		for name in names:
			character.player.special_pitch_names.append(name.strip_edges())
	
	var pitch_grooves = get_val.call("pitch_grooves", "")
	if pitch_grooves != "":
		var grooves = pitch_grooves.split(",")
		character.player.special_pitch_groove.clear()
		for groove in grooves:
			character.player.special_pitch_groove.append(float(groove.strip_edges()))
	
	# Appearance/Aesthetics
	character.player.portrait = get_val.call("portrait", "res://Assets/Player Portraits/placeholder portrait.png")
	character.player.head = get_val.call("head", "")
	character.player.haircut = get_val.call("haircut", "")
	character.player.glove = get_val.call("glove", "")
	character.player.shoe = get_val.call("shoe", "")
	character.player.body_type = get_val.call("body_type", "")
	character.player.skin_tone_primary = get_val.call("skin_tone_primary", "")
	character.player.skin_tone_secondary = get_val.call("skin_tone_secondary", "")
	character.player.complexion = get_val.call("complexion", "")
	character.player.playStyle = get_val.call("play_style", "")
	
	# Set special abilities based on play_style
	var play_style = character.player.playStyle
	match play_style:
		"Maestro":
			character.player.special_ability = "maestro"
			character.player.is_maestro = true
		"Machine":
			character.player.special_ability = "machine"
			character.player.is_machine = true
		"Spin Doctor":
			character.player.special_ability = "spin_doctor"
			character.player.is_spin_doctor = true
		"Workhorse":
			character.player.special_ability = "workhorse"
			character.player.is_workhorse = true
		_:
			# No special ability for other play styles
			character.player.special_ability = ""
			character.player.is_machine = false
			character.player.is_maestro = false
			character.player.is_spin_doctor = false
			character.player.is_workhorse = false
	character.player.match_type_icon()
	character.gender = get_val.call("gender", "m")
	
	# Attracted - defaults to all if blank
	var attracted_str = get_val.call("attracted", "")
	if attracted_str == "":
		character.attracted = {"m": true, "f": true, "i": true}
	else:
		# Parse comma-separated list (e.g., "m,f" or "f" or "m,i")
		character.attracted = {"m": false, "f": false, "i": false}
		var attracted_list = attracted_str.split(",")
		for gender_char in attracted_list:
			var g = gender_char.strip_edges().to_lower()
			if g in ["m", "f", "i"]:
				character.attracted[g] = true
	
	character.gang_affiliation = get_val.call("gang", "none")
	
	# Day job - blank becomes "none"
	var day_job_val = get_val.call("day_job", "")
	character.day_job = day_job_val if day_job_val != "" else "none"
	
	# Day job pay - blank becomes 0
	var day_job_pay_val = get_val.call("day_job_pay", "")
	character.day_job_pay = int(day_job_pay_val) if day_job_pay_val != "" else 0
	
	# Family members - all blank becomes 0
	var spouses_val = get_val.call("spouses", "")
	character.spouses = int(spouses_val) if spouses_val != "" else 0
	
	var children_val = get_val.call("children", "")
	character.children = int(children_val) if children_val != "" else 0
	
	var elders_val = get_val.call("elders", "")
	character.elders = int(elders_val) if elders_val != "" else 0
	
	var adults_val = get_val.call("adults", "")
	character.adults = int(adults_val) if adults_val != "" else 0
	
	# Off attributes
	var off_attrs = character.off_attributes
	off_attrs.positivity = get_int.call("positivity", 50)
	off_attrs.negativity = get_int.call("negativity", 50)
	off_attrs.influence = get_int.call("influence", 50)
	off_attrs.promiscuity = get_int.call("promiscuity", 50)
	off_attrs.loyalty = get_int.call("loyalty", 50)
	off_attrs.love_of_the_game = get_int.call("love_of_the_game", 50)
	off_attrs.professionalism = get_int.call("professionalism", 50)
	off_attrs.partying = get_int.call("partying", 50)
	off_attrs.potential = get_int.call("potential", 50)
	off_attrs.hustle = get_int.call("hustle", 50)
	off_attrs.hardiness = get_int.call("hardiness", 50)
	off_attrs.combat = get_int.call("combat", 50)
	
	# Contract data - only parse if contract type exists
	var contract_type = get_val.call("contract_type", "")
	if contract_type != "":
		character.contract.current_contract_type = contract_type
		character.contract.seasons_left = get_int.call("seasons_left", 1)
		character.contract.current_salary = get_int.call("salary", 0)
		character.contract.current_share = get_float.call("revenue_share", 0.0)
		character.contract.current_water = get_int.call("water", 0)
		character.contract.current_food = get_int.call("food", 0)
		character.contract.current_buyout = get_val.call("buyout", "free")
		character.contract.current_housing = get_val.call("housing", "none")
		character.contract.tryout_games_left = get_int.call("tryout_games", 0)
	
	# Store franchise_id as metadata on the character for placement
	var franchise_id = get_val.call("franchise_id", "")
	character.set_meta("franchise_id", franchise_id)
	
	# Job roles
	var job_roles_str = get_val.call("job_roles", "")
	if job_roles_str != "":
		var roles = job_roles_str.split(",")
		for role_pair in roles:
			var parts = role_pair.split(":")
			if parts.size() == 2:
				var role = parts[0].strip_edges()
				var value = parts[1].strip_edges().to_lower() in ["true", "1", "yes"]
				if character.job_roles.has(role):
					character.job_roles[role] = value
	
	character.preferred_job = get_val.call("preferred_job", "player")
	
	# Calculate player type if they're a player
	if character.job_roles.player:
		character.player.calculate_player_type()
	
	return character

func _place_character(character: Character) -> String:
	# Check if character has a contract with a franchise
	var has_contract = character.contract.current_contract_type != ""
	var franchise_id = character.get_meta("franchise_id", "")
	
	# If character has a contract and franchise, add to franchise
	if has_contract and franchise_id != "":
		# Get or create franchise
		if not franchises.has(franchise_id):
			franchises[franchise_id] = Franchise.new()
		
		var franchise = franchises[franchise_id]
		
		# Link contract to actual franchise object
		character.contract.current_team = franchise
		
		# Add to roster if they're a player
		if character.job_roles.player and character.preferred_job == "player":
			if franchise.team:
				franchise.team.add_player(character.player)
			else:
				# Franchise doesn't have team initialized yet, add to free agents for now
				var key = character.player.bio.first_name + "_" + character.player.bio.last_name
				free_agents[key] = character
				return "free_agent"
		# Otherwise add as staff member (implement based on preferred_job)
		# TODO: Add staff placement logic here
		
		return "franchised"
	
	# No contract or incomplete contract - add to free agents
	var key = character.player.bio.first_name + "_" + character.player.bio.last_name
	free_agents[key] = character
	return "free_agent"

# Utility function to get all characters
func get_all_characters() -> Array:
	var all_chars = []
	for character in free_agents.values():
		all_chars.append(character)
	for franchise in franchises.values():
		if franchise.team and franchise.team.roster:
			for player in franchise.team.roster:
				all_chars.append(player)
	return all_chars

# Search functions for querying imported data
func find_character_by_name(first: String, last: String) -> Character:
	var key = first + "_" + last
	if free_agents.has(key):
		return free_agents[key]
	return null

func get_free_agents_by_position(position: String) -> Array:
	var results = []
	for character in free_agents.values():
		if position in character.player.playable_positions:
			results.append(character)
	return results
