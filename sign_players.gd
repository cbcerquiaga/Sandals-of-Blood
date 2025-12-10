extends Control

@onready var filter_position_button: TextureButton = $main/Filter/FilterPosition
@onready var filter_style_button: TextureButton = $main/Filter/FilterStyle
@onready var filter_traits_button: TextureButton = $main/Filter/FilterTraits
@onready var sort_button: TextureButton = $main/Filter/Sort
@onready var view_button: TextureButton = $main/Filter/View

@onready var scrolling_area: VBoxContainer = $main/ScrollContainer/VBoxContainer
@onready var back_button: TextureButton = $main/Actions/Back
@onready var reset_button: TextureButton = $main/Actions/Reset
@onready var popup: PopupMenu = $PopupMenu

const avg_mobility_front: int = 80
const avg_physical_back: int = 70
const avg_power_front: int = 80
const avg_power_back: int = 70
const avg_skill_front: int = 75
const avg_skill_back: int = 85
const avg_mental_front: int = 68
const avg_mental_back: int = 80
const min_mobility_front: int = 70
const min_physical_back: int = 55
const min_power_front: int = 70
const min_power_back: int = 60
const min_skill_front: int = 65
const min_skill_back: int = 71
const min_mental_front: int = 60
const min_mental_back: int = 74

var filters = {
	"free_agents": true,
	"standard": true,
	"tradeable": true,
	"franchise": true,
	"staff": false,
	"positions": ["LF", "P", "RF", "LG", "K", "RG"],
	"min_positions": 1,
	"max_positions": 6,
	"styles": ["Goal Scorer", "Anti-Keeper", "Skull Cracker", "Support Forward", "Defender", "Bully", "Ball Hound", "Machine", "Workhorse", "Maestro", "Spin Doctor", "Ace", "Hatchet Man", "Track Hog"], #TODO: make sure these are all true
	"min_age": 0,
	"max_age": 120,
	"lefty": true,
	"righty": true,
	"full_scout_only": false,
	"attribute_filters": []
}

var all_characters: Array = []
var filtered_characters: Array = []
var current_sort_column: String = ""
var sort_ascending: bool = true
var current_view: String = "default"
var has_initialized_filters: bool
var comparables

func _ready():
	var importer = CharacterImporter.new()
	importer.import_npcs_from_csv("res://Assets/Rosters/debug_roster.csv")
	all_characters = importer.get_imported_npcs()
	format_page()
	fill_options()
	apply_filters()
	populate_scrollbar()
	initialize_filter_ui()
	popup.size = Vector2(800, 400)
	has_initialized_filters = false
	filter_position_button.grab_focus()

	
func _process(delta: float) -> void:
	if !has_initialized_filters:
		has_initialized_filters = initialize_filter_ui()

func player_selected(player: Character):
	print("Player selected: " + player.player.bio.last_name)
	popup.clear()
	if popup.id_pressed.is_connected(_on_popup_item_selected):
		popup.id_pressed.disconnect(_on_popup_item_selected)
	popup.id_pressed.connect(func(id: int): _on_popup_item_selected(id, player))
	if player.contract:
		match player.contract.type:
			"tradeable":
				popup.add_item("Trade", 0)
			"none", "free_agent":
				popup.add_item("Sign (Free)", 1)
			"standard":
				popup.add_item("Sign (1 Token)", 2)
			"franchise":
				popup.add_item("Sign (2 Tokens)", 3)
	else:
		popup.add_item("Sign (Free)", 1)
	
	#popup.add_item("Comparables", 4)
	popup.add_item("Career", 4)
	popup.popup_centered()
	
func _on_popup_item_selected(id: int, player: Character):
	match id:
		0:  # Trade
			print("Trade selected for: " + player.player.bio.last_name)
			# Add trade logic here
		1:  # Sign (Free)
			sign_player_pressed(player, 0)
		2:  # Sign (1 Token)
			sign_player_pressed(player, 1)
		3:  # Sign (2 Tokens)
			sign_player_pressed(player, 2)
		4:  # Comparables
			comparables_button_pressed(player)
		5:  # Career
			print("Career selected for: " + player.player.bio.last_name)
			#TODO: bring up player history

func comparables_button_pressed(player: Character): 
	print("Finding comparable contracts")
	var comparable_players = []
	var num_positions = player.player.playable_positions.size()
	
	for character in all_characters:
		if character == player:
			continue
		
		# Calculate similarity score (0-100)
		var similarity_score = calculate_similarity_score(player, character, num_positions)
		
		if similarity_score > 0:  # Only include players with some similarity
			comparable_players.append({
				"character": character, 
				"similarity": similarity_score
			})
	
	# Sort by similarity (highest first)
	comparable_players.sort_custom(func(a, b): return a.similarity > b.similarity)
	
	# Always get top 3 (or pad with lower similarity if needed)
	var top_3 = []
	for i in range(min(3, comparable_players.size())):
		top_3.append(comparable_players[i])
	
	# If we don't have 3 players, relax constraints and search again
	if top_3.size() < 3:
		print("Warning: Only found ", top_3.size(), " comparable players")
		# Could implement fallback logic here if needed
	
	# Get contract features and store in comparables
	# Store as array of [similarity, type, value, display, player_name]
	comparables = get_contract_features_data(top_3, player)
	
	print("Found ", top_3.size(), " comparable players with contract data")


func get_play_style_similarity(style1: String, style2: String) -> float:
	# Returns 0.0 to 1.0 based on how similar two play styles are
	
	# Exact match
	if style1 == style2:
		return 1.0
	
	# Define similarity groups
	var similarity_groups = {
		"Goal Scorer": ["Ball Hound"],
		"Ball Hound": ["Goal Scorer"],
		"Skull Cracker": ["Bully"],
		"Bully": ["Skull Cracker"],
		"Anti-Keeper": ["Support Forward"],
		"Support Forward": ["Anti-Keeper"],
		"Hatchet Man": ["Track Hog"],
		"Track Hog": ["Hatchet Man"],
		"Defender": ["Machine", "Workhorse"],
		"Machine": ["Defender", "Workhorse"],
		"Workhorse": ["Defender", "Machine"],
		"Spin Doctor": ["Ace"],
		"Ace": ["Spin Doctor"]
	}
	
	# Check if styles are in a similarity group together
	if similarity_groups.has(style1):
		if style2 in similarity_groups[style1]:
			return 0.7  # High similarity for grouped styles
	
	# Get primary positions for each style
	var style1_positions = get_positions_for_style(style1)
	var style2_positions = get_positions_for_style(style2)
	
	# Check if they share any positions (same position type)
	for pos1 in style1_positions:
		for pos2 in style2_positions:
			if pos1 == pos2:
				return 0.5  # Medium similarity for same position, different style
	
	# Different positions, different styles
	return 0.2  # Low but not zero similarity

func get_positions_for_style(style: String) -> Array:
	# Returns typical positions for each play style
	match style:
		"Goal Scorer", "Anti-Keeper", "Skull Cracker", "Support Forward":
			return ["LF", "RF"]
		"Defender", "Bully", "Ball Hound":
			return ["LG", "RG"]
		"Hatchet Man", "Track Hog", "Ace", "Spin Doctor":
			return ["P"]
		"Machine", "Workhorse", "Maestro":
			return ["K"]
	return []

func calculate_similarity_score(target_player: Character, compare_player: Character, target_num_positions: int) -> float:
	var score = 0.0
	var max_score = 100.0
	
	# Play style similarity (25 points max)
	var style_similarity = get_play_style_similarity(target_player.player.playStyle, compare_player.player.playStyle)
	score += style_similarity * 25.0
	
	# Age similarity (25 points max)
	var age_score = 0.0
	var age_diff = abs(compare_player.player.bio.years - target_player.player.bio.years)
	
	if target_player.player.bio.years < 20:
		age_score = 25.0 if compare_player.player.bio.years < 20 else 0.0
	elif target_player.player.bio.years > 35:
		age_score = 25.0 if compare_player.player.bio.years > 35 else 0.0
	else:
		# Linear decay: perfect match = 25, 10 years diff = 0
		age_score = max(0.0, 25.0 - (age_diff * 2.5))
	
	score += age_score
	
	# Position similarity (25 points max)
	var position_overlap = 0
	for pos in compare_player.player.playable_positions:
		if pos in target_player.player.playable_positions:
			position_overlap += 1
	
	var position_score = 0.0
	if target_num_positions > 0:
		var overlap_ratio = float(position_overlap) / float(max(target_num_positions, compare_player.player.playable_positions.size()))
		position_score = overlap_ratio * 25.0
	
	score += position_score
	
	# Overall rating similarity (25 points max)
	var target_overall = get_overall_rating(target_player.player)
	var compare_overall = get_overall_rating(compare_player.player)
	var rating_diff = abs(target_overall - compare_overall)
	
	# Linear decay: same rating = 25, 20+ points diff = 0
	var rating_score = max(0.0, 25.0 - (rating_diff * 1.25))
	score += rating_score
	
	return score

func get_contract_features_data(top_comparables: Array, target_player: Character) -> Array:
	# Returns 2D array: [[similarity_score, feature_type, feature_value, display_text, player_name], ...]
	var features_data = []
	
	for comparable in top_comparables:
		var character = comparable.character
		var similarity = comparable.similarity
		
		if not character.contract:
			continue
		
		# Contract type
		features_data.append([
			similarity,
			"contract_type",
			character.contract.type,
			"Contract: " + character.contract.type.capitalize(),
			character.player.bio.last_name
		])
		
		# Salary
		if character.contract.current_salary > 0:
			features_data.append([
				similarity,
				"salary",
				character.contract.current_salary,
				"Wage: " + str(character.contract.current_salary) + "¢/week",
				character.player.bio.last_name
			])
		
		# Food
		if character.contract.current_food > 0:
			features_data.append([
				similarity,
				"food",
				character.contract.current_food,
				"Food: " + str(character.contract.current_food) + " meals/week",
				character.player.bio.last_name
			])
		
		# Water
		if character.contract.current_water > 0:
			features_data.append([
				similarity,
				"water",
				character.contract.current_water,
				"Water: " + str(character.contract.current_water) + "L/week",
				character.player.bio.last_name
			])
		
		# Ownership share
		if character.contract.current_share > 0:
			features_data.append([
				similarity,
				"ownership",
				character.contract.current_share,
				"Ownership: " + str(character.contract.current_share) + "%",
				character.player.bio.last_name
			])
		
		# Buyout clause
		if character.contract.current_buyout != "free" and character.contract.current_buyout != "none":
			features_data.append([
				similarity,
				"buyout",
				character.contract.current_buyout,
				"Buyout: " + character.contract.current_buyout.capitalize(),
				character.player.bio.last_name
			])
		
		# Housing type
		if character.contract.current_housing != "none":
			features_data.append([
				similarity,
				"housing",
				character.contract.current_housing,
				"Housing: " + character.contract.current_housing.capitalize(),
				character.player.bio.last_name
			])
		
		# Contract length
		if character.contract.seasons_left > 0:
			features_data.append([
				similarity,
				"length",
				character.contract.seasons_left,
				"Length: " + str(character.contract.seasons_left) + " seasons",
				character.player.bio.last_name
			])
		
		# Focus
		if character.contract.current_focus != "none":
			features_data.append([
				similarity,
				"focus",
				character.contract.current_focus,
				"Focus: " + character.contract.current_focus.capitalize(),
				character.player.bio.last_name
			])
		
		# Promise
		if character.contract.current_promise != "none":
			features_data.append([
				similarity,
				"promise",
				character.contract.current_promise,
				"Promise: " + character.contract.current_promise.capitalize(),
				character.player.bio.last_name
			])
		
		# Bonus type and value
		if character.contract.current_bonus_type != "none":
			var bonus_text = "Bonus: " + character.contract.current_bonus_type.capitalize()
			if character.contract.current_bonus_prize != "none":
				bonus_text += " → " + character.contract.current_bonus_prize.capitalize()
			if character.contract.current_bonus_value > 0:
				bonus_text += " (" + str(character.contract.current_bonus_value) + ")"
			
			features_data.append([
				similarity,
				"bonus",
				{
					"type": character.contract.current_bonus_type,
					"prize": character.contract.current_bonus_prize,
					"value": character.contract.current_bonus_value
				},
				bonus_text,
				character.player.bio.last_name
			])
	
	# Shuffle to randomize feature selection
	features_data.shuffle()
	
	# Select 6 features, ensuring no more than 2 of the same type
	var selected_features = []
	var feature_type_counts = {}
	
	for feature in features_data:
		var feature_type = feature[1]  # Index 1 is the feature type
		var current_count = feature_type_counts.get(feature_type, 0)
		
		if current_count < 2:
			selected_features.append(feature)
			feature_type_counts[feature_type] = current_count + 1
			
			if selected_features.size() >= 6:
				break
	
	# Print selected features for debugging
	print("Selected contract features:")
	for feature in selected_features:
		print("  - Similarity: ", feature[0], " | ", feature[3], " (from ", feature[4], ")")
	
	return selected_features

func sign_player_pressed(player: Character, num_tokens: int = 0):
	print("Get that guy a contract!")
	var contract_scene = load("res://negotiate_contract.tscn").instantiate()
	comparables_button_pressed(player)
	if contract_scene.has_method("open_with_character"):
		player.scout_report.scout(100) #TODO: debug only
		contract_scene.open_with_character(player, num_tokens, player.scout_report, comparables)
	get_tree().root.add_child(contract_scene)
	get_tree().current_scene = contract_scene
	queue_free()

func _on_filter_position_pressed() -> void:
	$PositionsMenu.show()
	$main.hide()
	$TraitsMenu.hide()
	$StylesMenu.hide()
	$ViewMenu.hide()
	$PositionsMenu.scale = Vector2(3, 3)
	$PositionsMenu.position = Vector2(1000,500)
	$ColorRect.show()
	$ColorRect.size = Vector2(1200, 1000)

func _on_filter_style_pressed() -> void:
	$StylesMenu.show()
	$StylesMenu.position = Vector2(700, 500)
	$ColorRect.show()
	$ViewMenu.hide()
	$PositionsMenu.hide()
	$TraitsMenu.hide()
	$main.hide()
	$ColorRect.global_position = $StylesMenu.global_position - Vector2(200, 0)
	$ColorRect.size = Vector2(1800, 1200)

func _on_filter_traits_pressed(looking_for_players: bool = true) -> void:
	$TraitsMenu.show()
	if looking_for_players:
		$TraitsMenu/StaffRole.hide()
		$TraitsMenu/ContractType.show()
	else:
		$TraitsMenu/StaffRole.show()
		$TraitsMenu/ContractType.hide()
	$TraitsMenu.scale = Vector2(2, 2)
	$TraitsMenu.position = Vector2(200, 600)
	$ColorRect.show()
	$main.hide()
	$PositionsMenu.hide()
	$StylesMenu.hide()
	$ViewMenu.hide()

func _on_sort_pressed() -> void:
	popup.clear()
	var columns = get_columns_for_view()
	
	for i in range(columns.size()):
		popup.add_item(columns[i].display_name, i)
	
	# Disconnect previous connections to avoid duplicates
	if popup.id_pressed.is_connected(_on_sort_column_selected):
		popup.id_pressed.disconnect(_on_sort_column_selected)
	
	popup.id_pressed.connect(_on_sort_column_selected)
	popup.popup_centered()

func get_columns_for_view() -> Array:
	match current_view:
		"default":
			return [
				{"display_name": "First Name", "sort_key": "first_name"},
				{"display_name": "Nickname", "sort_key": "nickname"},
				{"display_name": "Last Name", "sort_key": "last_name"},
				{"display_name": "Contracted To", "sort_key": "team"},
				{"display_name": "Contract Type", "sort_key": "contract_type"},
				{"display_name": "Primary Position", "sort_key": "position"},
				{"display_name": "Secondary Positions", "sort_key": "num_positions"},
				{"display_name": "Age", "sort_key": "age"},
				{"display_name": "Player Type", "sort_key": "player_type"},
				{"display_name": "Overall Rating", "sort_key": "overall"},
			]
		"detailed":
			return [
				{"display_name": "First", "sort_key": "first_name"},
				{"display_name": "Last", "sort_key": "last_name"},
				{"display_name": "Speed", "sort_key": "speedRating"},
				{"display_name": "Blocking", "sort_key": "blocking"},
				{"display_name": "Positioning", "sort_key": "positioning"},
				{"display_name": "Aggression", "sort_key": "aggression"},
				{"display_name": "Reactions", "sort_key": "reactions"},
				{"display_name": "Durability", "sort_key": "durability"},
				{"display_name": "Strength", "sort_key": "power"},
				{"display_name": "Throwing", "sort_key": "throwing"},
				{"display_name": "Endurance", "sort_key": "endurance"},
				{"display_name": "Accuracy", "sort_key": "accuracy"},
				{"display_name": "Balance", "sort_key": "balance"},
				{"display_name": "Focus", "sort_key": "focus"},
				{"display_name": "Striking", "sort_key": "shooting"},
				{"display_name": "Toughness", "sort_key": "toughness"},
				{"display_name": "Confidence", "sort_key": "confidence"},
				{"display_name": "Agility", "sort_key": "agility"},
				{"display_name": "Faceoffs", "sort_key": "faceoffs"},
				{"display_name": "Discipline", "sort_key": "discipline"}
			]
		"relative":
			return [
				{"display_name": "First Name", "sort_key": "first_name"},
				{"display_name": "Nickname", "sort_key": "nickname"},
				{"display_name": "Last Name", "sort_key": "last_name"},
				{"display_name": "Contracted To", "sort_key": "team"},
				{"display_name": "Primary Position", "sort_key": "position"},
				{"display_name": "Age", "sort_key": "age"},
				{"display_name": "Player Type", "sort_key": "player_type"},
				{"display_name": "Overall Rating", "sort_key": "overall"},
				{"display_name": "Mobility", "sort_key": "mobility"},
				{"display_name": "Strength", "sort_key": "strength"},
				{"display_name": "Mental", "sort_key": "mental"}
			]
		"personal":
			return [
				{"display_name": "First Name", "sort_key": "first_name"},
				{"display_name": "Nickname", "sort_key": "nickname"},
				{"display_name": "Last Name", "sort_key": "last_name"},
				{"display_name": "Hometown", "sort_key": "hometown"},
				{"display_name": "Height", "sort_key": "height"},
				{"display_name": "Weight", "sort_key": "weight"},
				{"display_name": "Gender", "sort_key": "gender"},
				{"display_name": "Day Job", "sort_key": "day_job"},
				{"display_name": "Gang Affiliation", "sort_key": "gang"},
				{"display_name": "Family Size", "sort_key": "family_size"},
				{"display_name": "Home Cooking", "sort_key": "cooking_style"},
				{"display_name": "Best League", "sort_key": "best_league"},
				{"display_name": "Focus 1", "sort_key": "focus1"},
				{"display_name": "Focus 2", "sort_key": "focus2"},
				{"display_name": "Focus 3", "sort_key": "focus3"}
			]
		"contract":
			return [
				{"display_name": "First", "sort_key": "first_name"},
				{"display_name": "Last", "sort_key": "last_name"},
				{"display_name": "Type", "sort_key": "contract_type"},
				{"display_name": "Expiry", "sort_key": "expiry"},
				{"display_name": "Length", "sort_key": "length"},
				{"display_name": "Wage", "sort_key": "wage"},
				{"display_name": "Food", "sort_key": "food"},
				{"display_name": "Water", "sort_key": "water"},
				{"display_name": "Housing", "sort_key": "housing"},
				{"display_name": "Buyout", "sort_key": "buyout"},
				{"display_name": "Share", "sort_key": "ownership"}
			]
		"pitching":
			return [
				{"display_name": "First Name", "sort_key": "first_name"},
				{"display_name": "Nickname", "sort_key": "nickname"},
				{"display_name": "Last Name", "sort_key": "last_name"},
				{"display_name": "Hand", "sort_key": "hand"},
				{"display_name": "Throwing", "sort_key": "throwing"},
				{"display_name": "Power", "sort_key": "power"},
				{"display_name": "Accuracy", "sort_key": "accuracy"},
				{"display_name": "Confidence", "sort_key": "confidence"},
				{"display_name": "Curve", "sort_key": "focus"},
				{"display_name": "Face-Offs", "sort_key": "faceoffs"},
				{"display_name": "Speed", "sort_key": "speed"},
				{"display_name": "Endurance", "sort_key": "endurance"},
				{"display_name": "Durability", "sort_key": "durability"}
			]
	return []

func _on_sort_column_selected(id: int):
	var columns = get_columns_for_view()
	
	if id < columns.size():
		var sort_key = columns[id].sort_key
		
		if current_sort_column == sort_key:
			sort_ascending = !sort_ascending
		else:
			current_sort_column = sort_key
			sort_ascending = true
		
		sort_characters()
		populate_scrollbar()

func sort_characters():
	filtered_characters.sort_custom(func(a, b):
		var val_a = get_sort_value(a, current_sort_column)
		var val_b = get_sort_value(b, current_sort_column)
		
		if sort_ascending:
			return val_a < val_b
		else:
			return val_a > val_b
	)

func get_sort_value(character: Character, column: String):
	match column:
		"first_name":
			return character.player.bio.first_name
		"nickname":
			return character.player.bio.nickname if character.player.bio.nickname else ""
		"last_name":
			return character.player.bio.last_name
		"age":
			return character.player.bio.years
		"overall":
			return get_overall_rating(character.player)
		"position":
			return character.player.preferred_position if character.player.preferred_position else ""
		"num_positions":
			return character.player.playable_positions.size()
		"player_type":
			return character.player.playStyle
		"team":
			return get_contract_team(character)
		"contract_type":
			return get_contract_type(character)
		"hometown":
			return character.player.bio.hometown
		"height":
			return character.player.bio.feet * 12 + character.player.bio.inches
		"weight":
			return character.player.bio.pounds
		"gender":
			return character.gender
		"day_job":
			return 0 if character.day_job == "none" else 1
		"gang":
			return 0 if character.gang_affiliation == "none" else 1
		"family_size":
			return character.get_family_count()
		"cooking_style":
			return character.home_cooking_style
		"best_league":
			return character.best_league
		"expiry":
			return character.contract.seasons_remaining if character.contract and character.contract.has("seasons_remaining") else 0
		"length":
			return character.contract.length if character.contract else 0
		"wage":
			return character.contract.salary if character.contract else 0
		"ownership":
			return character.contract.ownership_share if character.contract and character.contract.has("ownership_share") else 0
		"hand":
			return 0 if character.player.bio.leftHanded else 1
		"throwing":
			return character.player.attributes.throwing
		"power":
			return character.player.attributes.power
		"accuracy":
			return character.player.attributes.accuracy
		"confidence":
			return character.player.attributes.confidence
		"focus":
			return character.player.attributes.focus
		"faceoffs":
			return character.player.attributes.faceoffs
		"speed":
			return character.player.attributes.speedRating
		"endurance":
			return character.player.attributes.endurance
		"durability":
			return character.player.attributes.durability
		"mobility":
			return (character.player.attributes.speedRating + character.player.attributes.agility + 
					character.player.attributes.endurance + character.player.attributes.reactions) / 4.0
		"strength":
			return (character.player.attributes.power + character.player.attributes.balance) / 2.0
		"mental":
			return (character.player.attributes.positioning + character.player.attributes.reactions + 
					character.player.attributes.discipline) / 3.0
		"speedRating":
			return character.player.attributes.speedRating
		"blocking":
			return character.player.attributes.blocking
		"positioning":
			return character.player.attributes.positioning
		"aggression":
			return character.player.attributes.aggression
		"reactions":
			return character.player.attributes.reactions
		"agility":
			return character.player.attributes.agility
		"discipline":
			return character.player.attributes.discipline
		"food":
			return character.contract.current_food if character.contract else 0
		"water":
			return character.contract.current_water if character.contract else 0
		"housing": #TODO: sort alphabetically
			if character.contract and character.contract.has("current_housing"):
				return character.contract.current_housing
			return ""
		"buyout": #TODO: sort as free, then 50%, then 100%, then 200%, then no buyout
			if character.contract and character.contract.has("current_buyout"):
				return character.contract.current_buyout
			return ""
	return 0

func _on_reset_pressed() -> void:
	filters = {
		"free_agents": true,
		"standard": true,
		"tradeable": true,
		"franchise": true,
		"staff": false,
		"positions": ["LF", "P", "RF", "LG", "K", "RG"],
		"min_positions": 1,
		"max_positions": 6,
		"styles": ["Goal Scorer", "Anti-Keeper", "Skull Cracker", "Support Forward", "Defender", "Bully", "Ball Hound", "Machine", "Workhorse", "Maestro", "Spin Doctor", "Ace", "Hatchet Man", "Track Hog"],
		"min_age": 0,
		"max_age": 120,
		"lefty": true,
		"righty": true,
		"full_scout_only": false,
		"attribute_filters": [],
	}
	apply_filters()
	populate_scrollbar()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://manager_hub_menu.tscn")

#region player_filtering
func apply_filters():
	filtered_characters = []
	
	for character in all_characters:
		if passes_all_filters(character):
			filtered_characters.append(character)

func passes_all_filters(character: Character) -> bool:
	# Contract type filters
	if character.contract:
		match character.contract.type:
			"free_agent", "none":
				if not filters.free_agents:
					return false
			"standard":
				if not filters.standard:
					return false
			"tradeable":
				if not filters.tradeable:
					return false
			"franchise":
				if not filters.franchise:
					return false
			"staff":
				if not filters.staff:
					return false
	else:
		if not filters.free_agents:
			return false
	#Position
	var has_valid_position = false
	for pos in character.player.playable_positions:
		if pos in filters.positions:
			has_valid_position = true
			break
	if not has_valid_position:
		return false
	#Position count
	var num_positions = character.player.playable_positions.size()
	if num_positions < filters.min_positions or num_positions > filters.max_positions:
		return false
	#Playing style
	if filters.styles.size() > 0:
		if not character.player.playStyle in filters.styles:
			return false
	#Age
	if character.player.bio.years < filters.min_age or character.player.bio.years > filters.max_age:
		return false
	#Handedness
	if character.player.bio.leftHanded and not filters.lefty:
		return false
	if not character.player.bio.leftHanded and not filters.righty:
		return false
	return true

func _on_filter_changed():
	apply_filters()
	populate_scrollbar()

func _on_free_agents_toggled(toggled_on: bool) -> void:
	filters.free_agents = toggled_on
	_on_filter_changed()

func _on_standard_toggled(toggled_on: bool) -> void:
	filters.standard = toggled_on
	_on_filter_changed()

func _on_tradeable_toggled(toggled_on: bool) -> void:
	filters.tradeable = toggled_on
	_on_filter_changed()

func _on_franchise_toggled(toggled_on: bool) -> void:
	filters.franchise = toggled_on
	_on_filter_changed()

func _on_staff_toggled(toggled_on: bool) -> void:
	filters.staff = toggled_on
	_on_filter_changed()

func _on_min_age_selected(index: int) -> void:
	filters.min_age = index * 5  # Assuming age options in increments of 5
	_on_filter_changed()

func _on_max_age_selected(index: int) -> void:
	filters.max_age = 15 + (index * 5)  # Start at 15, increment by 5
	if filters.max_age > 120:
		filters.max_age = 120
	_on_filter_changed()

func _on_lefty_toggled(toggled_on: bool) -> void:
	filters.lefty = toggled_on
	_on_filter_changed()

func _on_righty_toggled(toggled_on: bool) -> void:
	filters.righty = toggled_on
	_on_filter_changed()

func _on_plays_lf_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "LF" in filters.positions:
			filters.positions.append("LF")
	else:
		filters.positions.erase("LF")
	_on_filter_changed()

func _on_plays_p_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "P" in filters.positions:
			filters.positions.append("P")
	else:
		filters.positions.erase("P")
	_on_filter_changed()

func _on_plays_rf_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "RF" in filters.positions:
			filters.positions.append("RF")
	else:
		filters.positions.erase("RF")
	_on_filter_changed()

func _on_plays_lg_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "LG" in filters.positions:
			filters.positions.append("LG")
	else:
		filters.positions.erase("LG")
	_on_filter_changed()

func _on_plays_k_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "K" in filters.positions:
			filters.positions.append("K")
	else:
		filters.positions.erase("K")
	_on_filter_changed()

func _on_plays_rg_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "RG" in filters.positions:
			filters.positions.append("RG")
	else:
		filters.positions.erase("RG")
	_on_filter_changed()

func _on_min_positions_selected(index: int) -> void:
	filters.min_positions = index + 1
	_on_filter_changed()

func _on_max_positions_selected(index: int) -> void:
	filters.max_positions = index + 1
	_on_filter_changed()

#endregion

#region views
func _on_default_view_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_view = "default"
		populate_scrollbar()

func _on_relative_view_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_view = "relative"
		populate_scrollbar()

func _on_personal_view_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_view = "personal"
		populate_scrollbar()

func _on_contract_view_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_view = "contract"
		populate_scrollbar()

func _on_pitching_view_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_view = "pitching"
		populate_scrollbar()

#endregion

func format_page():
	var button_size = Vector2(160, 160)
	
	if filter_position_button:
		setup_button(filter_position_button, button_size)
		setup_button(filter_style_button, button_size)
		setup_button(filter_traits_button, button_size)
		setup_button(sort_button, button_size)
		setup_button(back_button, button_size)
		setup_button(view_button, button_size)
		setup_button(reset_button, button_size)
	if $ViewMenu/BackButton:
		setup_button($ViewMenu/BackButton, button_size)
		setup_button($StylesMenu/BackButton, button_size)
		setup_button($PositionsMenu/BackButton, button_size)
		setup_button($TraitsMenu/BackButton, button_size)
	var icon_size = Vector2(200, 200)
	scale_icon_group("StylesMenu/Forwards", icon_size)
	scale_icon_group("StylesMenu/Guards", icon_size)
	scale_icon_group("StylesMenu/Pitchers", icon_size)
	scale_icon_group("StylesMenu/Goalies", icon_size)

func setup_button(button: TextureButton, target_size: Vector2):
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = target_size
	button.set_deferred("size", target_size)

func scale_icon_group(parent_path: String, target_size: Vector2):
	var parent = get_node_or_null(parent_path)
	if not parent:
		return
	
	for child in parent.get_children():
		if child is TextureRect:
			child.custom_minimum_size = target_size
			if child.texture:
				var image = child.texture.get_image()
				if image:
					image.resize(int(target_size.x), int(target_size.y))
					child.texture = ImageTexture.create_from_image(image)
					
func create_header_row() -> PanelContainer:
	var header = PanelContainer.new()
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1)
	header.add_theme_stylebox_override("panel", stylebox)
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 30)
	header.add_child(hbox)
	var padding_label = Label.new()
	padding_label.custom_minimum_size = Vector2(150, 0)
	padding_label.text = ""
	hbox.add_child(padding_label)
	var columns = get_columns_for_view()
	for column in columns:
		var label = Label.new()
		label.text = column.display_name
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 28)
		label.custom_minimum_size = Vector2(150, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = 1.0
		label.clip_text = false
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label)
	var select_label = Label.new()
	select_label.text = "Select"
	select_label.custom_minimum_size = Vector2(120, 0)
	select_label.add_theme_color_override("font_color", Color.WHITE)
	select_label.add_theme_font_size_override("font_size", 28)
	select_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(select_label)
	return header
	
func populate_scrollbar():
	print("All characters size: " + str(all_characters.size()))
	print("Filtered characters size: " + str(filtered_characters.size()))
	for child in scrolling_area.get_children():
		child.queue_free()
	await get_tree().process_frame
	var header = create_header_row()
	scrolling_area.add_child(header)
	if filtered_characters.size() == 0:
		no_results()
		return
	var alternate_color = false
	for character in filtered_characters:
		print("Adding character: " + character.player.bio.last_name)
		var row = create_row(character, alternate_color)
		scrolling_area.add_child(row)
		alternate_color = !alternate_color
	print("Total rows added: " + str(scrolling_area.get_child_count()))

func create_row(character: Character, dark_row: bool) -> PanelContainer:
	var row = PanelContainer.new()
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.3, 0.3, 0.3) if dark_row else Color(0.2, 0.2, 0.2)
	row.add_theme_stylebox_override("panel", stylebox)
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)
	var padding_label = Label.new()
	padding_label.custom_minimum_size = Vector2(100, 0)
	padding_label.text = ""
	hbox.add_child(padding_label)
	
	match current_view:
		"default":
			add_default_view_columns(hbox, character)
		"relative":
			add_relative_view_columns(hbox, character)
		"personal":
			add_personal_view_columns(hbox, character)
		"contract":
			add_contract_view_columns(hbox, character)
		"pitching":
			add_pitching_view_columns(hbox, character)
		"detailed":
			add_detailed_view_columns(hbox, character)
	
	var select_button = Button.new()
	select_button.text = "Select"
	select_button.custom_minimum_size = Vector2(120, 0)  # Changed from (120, 60) to match header
	select_button.size_flags_horizontal = Control.SIZE_FILL  # Add this to match label behavior
	select_button.pressed.connect(func(): player_selected(character))
	hbox.add_child(select_button)
	
	return row

func add_label(container: HBoxContainer, text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 28)
	label.custom_minimum_size = Vector2(150, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = 1.0
	label.clip_text = false
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)


func add_default_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	add_label(row, get_contract_team(character))
	add_label(row, get_contract_type(character))
	add_label(row, get_primary_position(character))
	add_label(row, get_secondary_positions(character))
	add_label(row, "          " + str(character.player.bio.years))
	add_label(row, character.player.playStyle)
	add_label(row, str(get_overall_rating(character.player)))

func add_relative_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	add_label(row, get_contract_team(character))
	add_label(row, get_primary_position(character))
	add_label(row, str(character.player.bio.years))
	add_label(row, character.player.playStyle)
	add_label(row, str(get_overall_rating(character.player)))
	add_label(row, get_relative_rating(character, "mobility"))
	add_label(row, get_relative_rating(character, "strength"))
	add_label(row, get_relative_rating(character, "mental"))

func add_personal_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	add_label(row, character.player.bio.hometown)
	add_label(row, str(character.player.bio.feet) + "'" + str(character.player.bio.inches) + '"')
	add_label(row, str(character.player.bio.pounds) + " lbs")
	add_label(row, get_gender_string(character))
	add_label(row, "Yes" if character.day_job != "none" else "No")
	add_label(row, "Yes" if character.gang_affiliation != "none" else "No")
	add_label(row, str(character.get_family_count()))
	add_label(row, character.home_cooking_style)
	add_label(row, get_best_league_string(character.best_league))
	var top_focuses = get_top_3_focuses(character)
	var focus_list = top_focuses.split(", ")
	for i in range(3):
		if i < focus_list.size():
			add_label(row, focus_list[i])
		else:
			add_label(row, "-")

func add_contract_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.last_name)
	
	if character.contract:
		add_label(row, get_contract_type(character))
		add_label(row, str(character.contract.seasons_left) if character.contract.seasons_left != null else "0")
		add_label(row, str(character.contract.current_salary) + "¢")
		add_label(row, str(character.contract.current_food) if character.contract.current_food != null else "0")
		add_label(row, str(character.contract.current_water) if character.contract.current_water != null else "0")
		add_label(row, character.contract.current_housing if character.contract.current_housing != null else "N/A")
		add_label(row, character.contract.current_buyout if character.contract.current_buyout != null else "N/A")
		add_label(row, str(character.contract.current_share) + "%" if character.contract.current_share != null else "0%")
	else:
		for i in range(11):
			add_label(row, "N/A")

func add_pitching_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	add_label(row, "Left" if character.player.bio.leftHanded else "Right")
	add_label(row, str(character.player.attributes.throwing))
	add_label(row, str(character.player.attributes.power))
	add_label(row, str(character.player.attributes.accuracy))
	add_label(row, str(character.player.attributes.confidence))
	add_label(row, str(character.player.attributes.focus))

func get_contract_team(character: Character) -> String:
	if character.contract and character.contract.current_team != null:
		return character.contract.current_team.print_name()
	return "Free Agent"

func get_contract_type(character: Character) -> String:
	if character.contract:
		return character.contract.type.capitalize()
	return "N/A"

func get_primary_position(character: Character) -> String:
	if character.player.preferred_position:
		return character.player.preferred_position
	else:
		character.player.find_preferred_position()
		return character.player.preferred_position if character.player.preferred_position else "?"

func get_secondary_positions(character: Character) -> String:
	var primary = get_primary_position(character)
	var secondaries = []
	for pos in character.player.playable_positions:
		if pos != primary:
			secondaries.append(pos)
	return "/".join(secondaries) if secondaries.size() > 0 else "-"

func get_overall_rating(player: Player) -> int:
	var preferred = player.preferred_position if player.preferred_position else ""
	match preferred:
		"P":
			return player.calculate_pitcher_overall()
		"K":
			return player.calculate_keeper_overall()
		"LG", "RG":
			return player.calculate_guard_overall()
		"LF", "RF":
			return player.calculate_forward_overall()
		_:
			# Calculate all and return highest
			var ratings = [
				player.calculate_pitcher_overall(),
				player.calculate_keeper_overall(),
				player.calculate_guard_overall(),
				player.calculate_forward_overall()
			]
			ratings.sort()
			return ratings[ratings.size() - 1]

func get_relative_rating(character: Character, attribute_type: String) -> String:
	var position = get_primary_position(character)
	var is_front = position in ["LF", "RF", "P"]
	var value = 0.0
	
	match attribute_type:
		"mobility":
			value = (character.player.attributes.speedRating + character.player.attributes.agility + 
					 character.player.attributes.endurance + character.player.attributes.reactions) / 4.0
			var avg = avg_mobility_front if is_front else avg_physical_back
			return get_relative_symbol(value, avg)
		"strength":
			value = (character.player.attributes.power + character.player.attributes.balance) / 2.0
			var avg = avg_power_front if is_front else avg_power_back
			return get_relative_symbol(value, avg)
		"mental":
			value = (character.player.attributes.positioning + character.player.attributes.reactions + 
					 character.player.attributes.discipline) / 3.0
			var avg = avg_mental_front if is_front else avg_mental_back
			return get_relative_symbol(value, avg)
	
	return "±"

func get_relative_symbol(value: float, average: float) -> String:
	var diff = value - average
	var std_dev = 15.0  # Approximate standard deviation
	
	if diff > std_dev:
		return "++"
	elif diff > std_dev / 2:
		return "+"
	elif diff < -std_dev:
		return "--"
	elif diff < -std_dev / 2:
		return "-"
	else:
		return "±"

func get_gender_string(character: Character) -> String:
	match character.gender:
		"m":
			return "Male"
		"f":
			return "Female"
		"i":
			return "Intersex"
	return "Unknown"

func get_best_league_string(level: int) -> String:
	match level:
		0:
			return "N/A"
		1:
			return "B"
		2:
			return "A"
		3:
			return "AA"
		4:
			return "AAA"
	return "Unknown"

func fill_options():
	var min_age_option = $TraitsMenu/BioTraits/Age/Min
	var max_age_option = $TraitsMenu/BioTraits/Age/Max
	if min_age_option and min_age_option is OptionButton:
		min_age_option.clear()
		for i in range(0, 121):
			min_age_option.add_item(str(i), i)
	if max_age_option and max_age_option is OptionButton:
		max_age_option.clear()
		for i in range(0, 121):
			max_age_option.add_item(str(i), i)
	var min_positions_option = $PositionsMenu/NumPositions/Min
	var max_positions_option = $PositionsMenu/NumPositions/Max
	if min_positions_option and min_positions_option is OptionButton:
		min_positions_option.clear()
		for i in range(1, 7):#1-6
			min_positions_option.add_item(str(i), i - 1)
	
	if max_positions_option and max_positions_option is OptionButton:
		max_positions_option.clear()
		for i in range(1, 7):
			max_positions_option.add_item(str(i), i - 1)

func no_results():
	for child in scrolling_area.get_children():
		child.free()
	var message_container = HBoxContainer.new()
	message_container.custom_minimum_size = Vector2(0, 100)
	message_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var no_results_label = Label.new()
	no_results_label.text = "No players were found matching the search criteria"
	no_results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_container.add_child(no_results_label)
	scrolling_area.add_child(message_container)


func _on_back_button_pressed() -> void:
	$TraitsMenu.hide()
	$PositionsMenu.hide()
	$StylesMenu.hide()
	$ViewMenu.hide()
	$ColorRect.hide()
	populate_scrollbar()
	$main.show()
	$main/Filter/FilterPosition.grab_focus()

func initialize_filter_ui():
	var success = true
	
	var nodes_to_set = [ #block signals while setting these to keep the scrollbar from drawing more than once
		$TraitsMenu/BioTraits/Age/Min,
		$TraitsMenu/BioTraits/Age/Max,
		$PositionsMenu/NumPositions/Min,
		$PositionsMenu/NumPositions/Max,
		$TraitsMenu/ContractType/FreeAgents,
		$TraitsMenu/ContractType/Standard,
		$TraitsMenu/ContractType/Tradeable,
		$TraitsMenu/ContractType/Franchise,
		$TraitsMenu/ContractType/Staff,
		get_node_or_null("TraitsMenu/BioTraits/Handedness/Lefty"),
		get_node_or_null("TraitsMenu/BioTraits/Handedness/Righty"),
		get_node_or_null("PositionsMenu/Positions/LF"),
		get_node_or_null("PositionsMenu/Positions/P"),
		get_node_or_null("PositionsMenu/Positions/RF"),
		get_node_or_null("PositionsMenu/Positions/LG"),
		get_node_or_null("PositionsMenu/Positions/K"),
		get_node_or_null("PositionsMenu/Positions/RG")
	]
	for node in nodes_to_set:
		if node:
			node.set_block_signals(true)
	$TraitsMenu/BioTraits/Age/Min.selected = filters.min_age
	$TraitsMenu/BioTraits/Age/Max.selected = filters.max_age
	$PositionsMenu/NumPositions/Min.selected = filters.min_positions - 1
	$PositionsMenu/NumPositions/Max.selected = filters.max_positions - 1
	$TraitsMenu/ContractType/FreeAgents.button_pressed = filters.free_agents
	$TraitsMenu/ContractType/Standard.button_pressed = filters.standard
	$TraitsMenu/ContractType/Tradeable.button_pressed = filters.tradeable
	$TraitsMenu/ContractType/Franchise.button_pressed = filters.franchise
	$TraitsMenu/ContractType/Staff.button_pressed = filters.staff
	
	var filtering_left = get_node_or_null("TraitsMenu/BioTraits/Handedness/Lefty")
	if filtering_left and filtering_left is CheckButton:
		filtering_left.button_pressed = filters.lefty
	else:
		success = false
		
	var filtering_right = get_node_or_null("TraitsMenu/BioTraits/Handedness/Righty")
	if filtering_right and filtering_right is CheckButton:
		filtering_right.button_pressed = filters.righty
	else:
		success = false
		
	var lf_node = get_node_or_null("PositionsMenu/Positions/LF")
	if lf_node and lf_node is CheckButton:
		lf_node.button_pressed = "LF" in filters.positions
	else:
		success = false
		
	var p_node = get_node_or_null("PositionsMenu/Positions/P")
	if p_node and p_node is CheckButton:
		p_node.button_pressed = "P" in filters.positions
	else:
		success = false
		
	var rf_node = get_node_or_null("PositionsMenu/Positions/RF")
	if rf_node and rf_node is CheckButton:
		rf_node.button_pressed = "RF" in filters.positions
	else:
		success = false
		
	var lg_node = get_node_or_null("PositionsMenu/Positions/LG")
	if lg_node and lg_node is CheckButton:
		lg_node.button_pressed = "LG" in filters.positions
	else:
		success = false
		
	var k_node = get_node_or_null("PositionsMenu/Positions/K")
	if k_node and k_node is CheckButton:
		k_node.button_pressed = "K" in filters.positions
	else:
		success = false
		
	var rg_node = get_node_or_null("PositionsMenu/Positions/RG")
	if rg_node and rg_node is CheckButton:
		rg_node.button_pressed = "RG" in filters.positions
	else:
		success = false
	for node in nodes_to_set:
		if node:
			node.set_block_signals(false)
	
	return success

func _on_view_pressed() -> void:
	popup.clear()
	if popup.id_pressed.is_connected(_on_view_item_selected):
		popup.id_pressed.disconnect(_on_view_item_selected)
	popup.add_item("Default View", 0)
	popup.add_item("Relative View", 1)
	popup.add_item("Detailed View", 2)
	popup.add_item("Personal View", 3)
	popup.add_item("Contract View", 4)
	popup.add_item("Pitching View", 5)
	popup.id_pressed.connect(_on_view_item_selected)
	popup.popup_centered()


func _on_view_item_selected(id: int) -> void:
	match id:
		0:  # Default View
			current_view = "default"
		1:  # Relative View
			current_view = "relative"
		2: # Detailed view
			current_view = "detailed"
		3:  # Personal View
			current_view = "personal"
		4:  # Contract View
			current_view = "contract"
		5:  # Pitching View
			current_view = "pitching"
			
	populate_scrollbar()

func add_detailed_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.last_name)
	add_label(row, str(character.player.attributes.speedRating))
	add_label(row, str(character.player.attributes.blocking))
	add_label(row, str(character.player.attributes.positioning))
	add_label(row, str(character.player.attributes.aggression))
	add_label(row, str(character.player.attributes.reactions))
	add_label(row, str(character.player.attributes.durability))
	add_label(row, str(character.player.attributes.power))
	add_label(row, str(character.player.attributes.throwing))
	add_label(row, str(character.player.attributes.endurance))
	add_label(row, str(character.player.attributes.accuracy))
	add_label(row, str(character.player.attributes.balance))
	add_label(row, str(character.player.attributes.focus))
	add_label(row, str(character.player.attributes.shooting))
	add_label(row, str(character.player.attributes.toughness))
	add_label(row, str(character.player.attributes.confidence))
	add_label(row, str(character.player.attributes.agility))
	add_label(row, str(character.player.attributes.faceoffs))
	add_label(row, str(character.player.attributes.discipline))
	
func get_top_3_focuses(character: Character) -> String:
	if character.top_focuses and character.top_focuses.size() > 0:
		var focuses = []
		for i in range(min(3, character.top_focuses.size())):
			focuses.append(character.top_focuses[i])
		return ", ".join(focuses)
	var focuses_dict = character.contract_focuses
	if focuses_dict.size() == 0:
		return ""
	var sorted_focuses = focuses_dict.keys()
	sorted_focuses.sort_custom(func(a, b): return focuses_dict[a] > focuses_dict[b])
	var top_focuses = []
	for i in range(min(3, sorted_focuses.size())):
		top_focuses.append(sorted_focuses[i])
	return ", ".join(top_focuses)
