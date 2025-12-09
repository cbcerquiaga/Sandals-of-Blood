extends Node
class_name CharacterImporter


@export var csv_file_path: String = "res://Assets/Rosters/debug_roster.csv"

var imported_npcs: Array[Character] = []

func _ready():
	import_npcs_from_csv(csv_file_path)

func import_npcs_from_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open CSV file: " + path)
		return
	var header = file.get_csv_line() #read header row
	var column_indices = {} #store column indices for faster lookup
	for i in range(header.size()):
		column_indices[header[i]] = i
	var line_number = 1
	while file.get_position() < file.get_length():
		var row = file.get_csv_line()
		line_number += 1
		
		if row.size() == 0 or (row.size() == 1 and row[0] == ""):
			continue
			
		if row.size() != header.size():
			push_error("Row " + str(line_number) + " has incorrect number of columns. Expected: " + str(header.size()) + ", Got: " + str(row.size()))
			continue
			
		var npc = Character.new()
		set_npc_properties(npc, row, column_indices)
		var player = create_player_from_csv(row, column_indices)
		var contract = create_contract_from_csv(row, column_indices)
		npc.player = player
		npc.contract = contract
		
		imported_npcs.append(npc)
		print("Imported NPC: " + npc.player.bio.first_name + " " + npc.player.bio.last_name)
	
	file.close()
	print("Import complete. Loaded " + str(imported_npcs.size()) + " NPCs")

func set_npc_properties(npc: Character, row: PackedStringArray, column_indices: Dictionary) -> void:
	npc.preferred_job = get_csv_value(row, column_indices, "preferred_job", "player")
	npc.day_job = get_csv_value(row, column_indices, "day_job", "none")
	npc.home_cooking_style = get_csv_value(row, column_indices, "home_cooking", "bbq")
	npc.day_job_pay = get_csv_value(row, column_indices, "day_job_pay", "0").to_int()
	npc.gender = get_csv_value(row, column_indices, "gender", "m")
	npc.gang_affiliation = get_csv_value(row, column_indices, "gang_affiliation", "")
	npc.spouses = get_csv_value(row, column_indices, "spouses", "0").to_int()
	npc.children = get_csv_value(row, column_indices, "children", "0").to_int()
	npc.elders = get_csv_value(row, column_indices, "elders", "0").to_int()
	npc.adults = get_csv_value(row, column_indices, "adults", "0").to_int()
	npc.family = npc.spouses + npc.children + npc.elders + npc.adults
	npc.best_league = get_csv_value(row, column_indices, "best_league", "0").to_int()
	npc.off_attributes = {
		"positivity": get_csv_value(row, column_indices, "positivity", "50").to_int(),
		"negativity": get_csv_value(row, column_indices, "negativity", "50").to_int(),
		"influence": get_csv_value(row, column_indices, "influence", "50").to_int(),
		"promiscuity": get_csv_value(row, column_indices, "promiscuity", "50").to_int(),
		"loyalty": get_csv_value(row, column_indices, "loyalty", "50").to_int(),
		"love_of_the_game": get_csv_value(row, column_indices, "love_of_the_game", "50").to_int(),
		"professionalism": get_csv_value(row, column_indices, "professionalism", "50").to_int(),
		"partying": get_csv_value(row, column_indices, "partying", "50").to_int(),
		"potential": get_csv_value(row, column_indices, "potential", "50").to_int(),
		"hustle": get_csv_value(row, column_indices, "hustle", "50").to_int(),
		"talent": get_csv_value(row, column_indices, "talent", "50").to_int(),
		"hardiness": get_csv_value(row, column_indices, "hardiness", "50").to_int(),
		"combat": get_csv_value(row, column_indices, "combat", "50").to_int()
	}
	
	npc.contract_focuses = {
		"value": get_csv_value(row, column_indices, "contract_focus_value", "0.0").to_float(),
		"stability": get_csv_value(row, column_indices, "contract_focus_stability", "0.0").to_float(),
		"flexibility": get_csv_value(row, column_indices, "contract_focus_flexibility", "0.0").to_float(),
		"satiety": get_csv_value(row, column_indices, "contract_focus_satiety", "0.0").to_float(),
		"hydration": get_csv_value(row, column_indices, "contract_focus_hydration", "0.0").to_float(),
		"hometown": get_csv_value(row, column_indices, "contract_focus_hometown", "0.0").to_float(),
		"housing": get_csv_value(row, column_indices, "contract_focus_housing", "0.0").to_float(),
		"house_type": get_csv_value(row, column_indices, "contract_focus_house_type", "room"),
		"gameday": get_csv_value(row, column_indices, "contract_focus_gameday", "0.0").to_float(),
		"travel": get_csv_value(row, column_indices, "contract_focus_travel", "0.0").to_float(),
		"medical": get_csv_value(row, column_indices, "contract_focus_medical", "0.0").to_float(),
		"party": get_csv_value(row, column_indices, "contract_focus_party", "0.0").to_float(),
		"chill": get_csv_value(row, column_indices, "contract_focus_chill", "0.0").to_float(),
		"win_now": get_csv_value(row, column_indices, "contract_focus_win_now", "0.0").to_float(),
		"win_later": get_csv_value(row, column_indices, "contract_focus_win_later", "0.0").to_float(),
		"loyalty": get_csv_value(row, column_indices, "contract_focus_loyalty", "0.0").to_float(),
		"opportunity": get_csv_value(row, column_indices, "contract_focus_opportunity", "0.0").to_float(),
		"community": get_csv_value(row, column_indices, "contract_focus_community", "0.0").to_float(),
		"development": get_csv_value(row, column_indices, "contract_focus_development", "0.0").to_float(),
		"safety": get_csv_value(row, column_indices, "contract_focus_safety", "0.0").to_float(),
		"education": get_csv_value(row, column_indices, "contract_focus_education", "0.0").to_float(),
		"trade": get_csv_value(row, column_indices, "contract_focus_trade", "0.0").to_float(),
		"farming": get_csv_value(row, column_indices, "contract_focus_farming", "0.0").to_float(),
		"day_life": get_csv_value(row, column_indices, "contract_focus_day_life", "0.0").to_float(),
		"night_life": get_csv_value(row, column_indices, "contract_focus_night_life", "0.0").to_float(),
		"welfare": get_csv_value(row, column_indices, "contract_focus_welfare", "0.0").to_float()
	}
	
	npc.top_focuses = calculate_top_focuses(npc.contract_focuses)
	
	npc.attracted = {
		"m": get_csv_value(row, column_indices, "attracted_m", "false").to_lower() == "true",
		"f": get_csv_value(row, column_indices, "attracted_f", "false").to_lower() == "true",
		"i": get_csv_value(row, column_indices, "attracted_i", "false").to_lower() == "true"
	}

	npc.job_roles = {
		"player": get_csv_value(row, column_indices, "job_roles_player", "false").to_lower() == "true",
		"coach": get_csv_value(row, column_indices, "job_roles_coach", "false").to_lower() == "true",
		"scout": get_csv_value(row, column_indices, "job_roles_scout", "false").to_lower() == "true",
		"security": get_csv_value(row, column_indices, "job_roles_security", "false").to_lower() == "true",
		"surgeon": get_csv_value(row, column_indices, "job_roles_surgeon", "false").to_lower() == "true",
		"medic": get_csv_value(row, column_indices, "job_roles_medic", "false").to_lower() == "true",
		"promoter": get_csv_value(row, column_indices, "job_roles_promoter", "false").to_lower() == "true",
		"grounds": get_csv_value(row, column_indices, "job_roles_grounds", "false").to_lower() == "true",
		"equipment": get_csv_value(row, column_indices, "job_roles_equipment", "false").to_lower() == "true",
		"cook": get_csv_value(row, column_indices, "job_roles_cook", "false").to_lower() == "true",
		"accountant": get_csv_value(row, column_indices, "job_roles_accountant", "false").to_lower() == "true",
		"entourage": get_csv_value(row, column_indices, "job_roles_entourage", "false").to_lower() == "true"
	}
	
	npc.staff_skills = {
		"physical_training": get_csv_value(row, column_indices, "physical_training", "10").to_int(),
		"technical_training": get_csv_value(row, column_indices, "technical_training", "10").to_int(),
		"mental_training": get_csv_value(row, column_indices, "mental_training", "10").to_int(),
		"talent_eval": get_csv_value(row, column_indices, "talent_eval", "10").to_int(),
		"talent_spotting": get_csv_value(row, column_indices, "talent_spotting", "10").to_int(),
		"scouting_speed": get_csv_value(row, column_indices, "scouting_speed", "10").to_int(),
		"deescalation": get_csv_value(row, column_indices, "deescalation", "10").to_int(),
		"anti_banditry": get_csv_value(row, column_indices, "anti_banditry", "10").to_int(),
		"escorting": get_csv_value(row, column_indices, "escorting", "10").to_int(),
		"trauma": get_csv_value(row, column_indices, "trauma", "10").to_int(),
		"ortho": get_csv_value(row, column_indices, "ortho", "10").to_int(),
		"medicine": get_csv_value(row, column_indices, "medicine", "10").to_int(),
		"stretching": get_csv_value(row, column_indices, "stretching", "10").to_int(),
		"first_aid": get_csv_value(row, column_indices, "first_aid", "10").to_int(),
		"rehab": get_csv_value(row, column_indices, "rehab", "10").to_int(),
		"attraction": get_csv_value(row, column_indices, "attraction", "10").to_int(),
		"sponsorship": get_csv_value(row, column_indices, "sponsorship", "10").to_int(),
		"networking": get_csv_value(row, column_indices, "networking", "10").to_int(),
		"masonry": get_csv_value(row, column_indices, "masonry", "10").to_int(),
		"carpentry": get_csv_value(row, column_indices, "carpentry", "10").to_int(),
		"painting": get_csv_value(row, column_indices, "painting", "10").to_int(),
		"sewing": get_csv_value(row, column_indices, "sewing", "10").to_int(),
		"carrying": get_csv_value(row, column_indices, "carrying", "10").to_int(),
		"acquisitions": get_csv_value(row, column_indices, "acquisitions", "10").to_int(),
		"line_cooking": get_csv_value(row, column_indices, "line_cooking", "10").to_int(),
		"home_cooking": get_csv_value(row, column_indices, "home_cooking", "10").to_int(),
		"fine_cooking": get_csv_value(row, column_indices, "fine_cooking", "10").to_int(),
		"auditing": get_csv_value(row, column_indices, "auditing", "10").to_int(),
		"budgeting": get_csv_value(row, column_indices, "budgeting", "10").to_int(),
		"bidding": get_csv_value(row, column_indices, "bidding", "10").to_int(),
		"raging": get_csv_value(row, column_indices, "raging", "10").to_int(),
		"chilling": get_csv_value(row, column_indices, "chilling", "10").to_int(),
		"intimacy": get_csv_value(row, column_indices, "intimacy", "10").to_int(),
		"charisma": get_csv_value(row, column_indices, "charisma", "10").to_int(),
		"helpfulness": get_csv_value(row, column_indices, "helpfulness", "10").to_int(),
		"longevity": get_csv_value(row, column_indices, "longevity", "10").to_int()
	}

func calculate_top_focuses(focuses: Dictionary) -> Array:
	var focus_array = []
	for focus_name in focuses:
		var focus_value = focuses[focus_name]
		if focus_value is float or focus_value is int:
			focus_array.append({"name": focus_name, "value": float(focus_value)})
	focus_array.sort_custom(func(a, b): return a.value > b.value)
	var primary_focuses = ["stability", "flexibility", "value"] #always have at least one of these
	var has_primary = false
	var top_names = []
	for i in range(min(5, focus_array.size())):
		if focus_array[i].name in primary_focuses:
			has_primary = true
			break
	if not has_primary:
		var best_primary = null
		var best_primary_value = -INF
		for focus in focus_array:
			if focus.name in primary_focuses and focus.value > best_primary_value:
				best_primary = focus
				best_primary_value = focus.value
		if best_primary:
			top_names.append(best_primary.name)
		for i in range(min(4, focus_array.size())):
			if focus_array[i].name not in primary_focuses:
				top_names.append(focus_array[i].name)
	else:
		for i in range(min(5, focus_array.size())):
			top_names.append(focus_array[i].name)
	return top_names

func create_player_from_csv(row: PackedStringArray, column_indices: Dictionary) -> Player:
	var player = Player.new()
	player.bio = {
		"first_name": get_csv_value(row, column_indices, "first_name", "Unknown"),
		"last_name": get_csv_value(row, column_indices, "last_name", "Unknown"),
		"nickname": get_csv_value(row, column_indices, "nickname", ""),
		"hometown": get_csv_value(row, column_indices, "hometown", "Unknown"),
		"leftHanded": get_csv_value(row, column_indices, "leftHanded", "false").to_lower() == "true",
		"feet": get_csv_value(row, column_indices, "feet", "5").to_int(),
		"inches": get_csv_value(row, column_indices, "inches", "10").to_int(),
		"pounds": get_csv_value(row, column_indices, "pounds", "200").to_int(),
		"years": get_csv_value(row, column_indices, "years", "25").to_int()
	}
	player.preferred_position = get_csv_value(row, column_indices, "preferred_position", "P")
	player.declared_pitcher = get_csv_value(row, column_indices, "declared_pitcher", "false").to_lower() == "true"
	player.playable_positions = []
	var positions = ["P", "K", "LG", "RG", "LF", "RF"]
	for position in positions:
		if get_csv_value(row, column_indices, "playable_" + position, "false").to_lower() == "true":
			player.playable_positions.append(position)
	#if no playable positions were specified, use preferred position
	if player.playable_positions.size() == 0:
		player.playable_positions = [player.preferred_position]
	player.attributes = {
		"speedRating": get_csv_value(row, column_indices, "speedRating", "50").to_int(),
		"speed": 0.0,  #ignore, gets  set later
		"sprint_speed": 0.0,  #gets calculated later
		"blocking": get_csv_value(row, column_indices, "blocking", "50").to_int(),
		"positioning": get_csv_value(row, column_indices, "positioning", "50").to_int(),
		"aggression": get_csv_value(row, column_indices, "aggression", "50").to_int(),
		"reactions": get_csv_value(row, column_indices, "reactions", "50").to_int(),
		"durability": get_csv_value(row, column_indices, "durability", "50").to_int(),
		"power": get_csv_value(row, column_indices, "power", "50").to_int(),
		"throwing": get_csv_value(row, column_indices, "throwing", "50").to_int(),
		"endurance": get_csv_value(row, column_indices, "endurance", "50").to_int(),
		"accuracy": get_csv_value(row, column_indices, "accuracy", "50").to_int(),
		"balance": get_csv_value(row, column_indices, "balance", "50").to_int(),
		"focus": get_csv_value(row, column_indices, "focus", "50").to_int(),
		"shooting": get_csv_value(row, column_indices, "shooting", "50").to_int(),
		"toughness": get_csv_value(row, column_indices, "toughness", "50").to_int(),
		"confidence": get_csv_value(row, column_indices, "confidence", "50").to_int(),
		"agility": get_csv_value(row, column_indices, "agility", "50").to_int(),
		"faceoffs": get_csv_value(row, column_indices, "faceoffs", "50").to_int(),
		"discipline": get_csv_value(row, column_indices, "discipline", "50").to_int(),
	}
	player.attributes.speed = player.attributes.speedRating + 35.0
	player.attributes.sprint_speed = (player.attributes.speedRating - 5) * 2.0
	player.status = {
		"momentum": 0,
		"energy": 100,
		"health": 100,
		"boost": 100,
		"max_energy": 100,
		"max_boost": 100,
		"stability": 100,
		"groove": 100,
		"anger": 0,
		"baseline_anger": 0,
		"starter": false
	}
	player.reset_game_stats()
	player.calculate_player_type()
	return player

func create_contract_from_csv(row: PackedStringArray, column_indices: Dictionary) -> Contract:
	var contract = Contract.new()
	#TODO: implement set_team() method in Contract class
	# contract.current_team = get_csv_value(row, column_indices, "contract_team", "")
	contract.type = get_csv_value(row, column_indices, "contract_type", "standard")
	contract.seasons_left = get_csv_value(row, column_indices, "contract_seasons_left", "1").to_int()
	contract.tryout_games_left = get_csv_value(row, column_indices, "contract_tryout_games_left", "0").to_int()
	contract.current_salary = get_csv_value(row, column_indices, "contract_salary", "0").to_int()
	contract.current_share = get_csv_value(row, column_indices, "contract_share", "0").to_int()
	contract.current_water = get_csv_value(row, column_indices, "contract_water", "0").to_int()
	contract.current_food = get_csv_value(row, column_indices, "contract_food", "0").to_int()
	contract.current_buyout = get_csv_value(row, column_indices, "contract_buyout", "free")
	contract.current_housing = get_csv_value(row, column_indices, "contract_housing", "none")
	contract.current_focus = get_csv_value(row, column_indices, "contract_focus", "value")
	contract.current_promise = get_csv_value(row, column_indices, "contract_promise", "none")
	contract.current_bonus_type = get_csv_value(row, column_indices, "contract_bonus_type", "gp")
	contract.current_bonus_prize = get_csv_value(row, column_indices, "contract_bonus_prize", "salary_raise")
	contract.current_bonus_value = get_csv_value(row, column_indices, "contract_bonus_value", "1").to_int()
	return contract

func get_csv_value(row: PackedStringArray, column_indices: Dictionary, column_name: String, default_value = "") -> String:
	if column_indices.has(column_name) and column_indices[column_name] < row.size():
		var value = row[column_indices[column_name]]
		if value != "":
			return value
	return default_value

func get_imported_npcs() -> Array[Character]:
	return imported_npcs

func clear_imported_npcs() -> void:
	imported_npcs.clear()
