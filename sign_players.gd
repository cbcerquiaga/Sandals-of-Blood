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

# Filter state
var filters = {
	"free_agents": true,
	"standard": true,
	"tradeable": true,
	"franchise": true,
	"staff": false,
	"positions": ["LF", "P", "RF", "LG", "K", "RG"],
	"min_positions": 1,
	"max_positions": 6,
	"styles": [],
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

func _ready():
	var importer = CharacterImporter.new()
	var result = importer.import_from_csv("res://data/characters.csv")
	if result.success:
		print("Imported %d characters" % result.total_imported)
		all_characters = result.characters
	format_page()
	fill_options()
	apply_filters()
	populate_scrollbar()
	filter_position_button.grab_focus()

func player_selected(player: Character):
	print("Player selected: " + player.player.bio.last_name)
	popup.clear()
	
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
	
	popup.add_item("Comparables", 4)
	popup.add_item("Career", 5)
	popup.popup_centered()

func comparables_button_pressed(player: Character):
	print("Finding comparable contracts")
	var comparable_players = []
	var num_positions = player.player.playable_positions.size()
	
	for character in all_characters:
		if character == player:
			continue
		
		# Check player type match
		if character.player.playStyle != player.player.playStyle:
			continue
		
		# Age filtering
		var age_match = false
		if player.player.bio.years < 20:
			age_match = character.player.bio.years < 20
		elif player.player.bio.years > 35:
			age_match = character.player.bio.years > 35
		else:
			age_match = abs(character.player.bio.years - player.player.bio.years) <= 2
		
		if not age_match:
			continue
		
		# Calculate similarity score
		var position_similarity = float(character.player.playable_positions.size()) / float(num_positions)
		if position_similarity > 1.0:
			position_similarity = 1.0 / position_similarity
		
		var overall_player = get_overall_rating(player.player)
		var overall_char = get_overall_rating(character.player)
		var rating_similarity = 1.0 - (abs(overall_player - overall_char) / 100.0)
		
		var total_similarity = (position_similarity + rating_similarity) / 2.0
		comparable_players.append({"character": character, "similarity": total_similarity})
	
	# Sort by similarity
	comparable_players.sort_custom(func(a, b): return a.similarity > b.similarity)
	
	# Pick top 3
	var top_3 = []
	for i in range(min(3, comparable_players.size())):
		top_3.append(comparable_players[i].character)
	
	if top_3.size() >= 3:
		pick_6_contract_features(top_3[0], top_3[1], top_3[2])
	else:
		print("Not enough comparable players found")

func pick_6_contract_features(player1: Character, player2: Character, player3: Character):
	print("Here are your similar players:")
	print(player1.player.bio.last_name, ", ", player2.player.bio.last_name, ", ", player3.player.bio.last_name)
	
	var all_features = []
	
	# Collect all contract features from the three comparable players
	for p in [player1, player2, player3]:
		if p.contract:
			# Contract type
			all_features.append({
				"type": "contract_type",
				"value": p.contract.type,
				"display": "Contract: " + p.contract.type.capitalize(),
				"player": p.player.bio.last_name
			})
			
			# Wage
			all_features.append({
				"type": "wage",
				"value": p.contract.salary,
				"display": "Wage: " + str(p.contract.salary) + "¢/week",
				"player": p.player.bio.last_name
			})
			
			# Food
			if p.contract.has("food"):
				all_features.append({
					"type": "food",
					"value": p.contract.food,
					"display": "Food: " + str(p.contract.food) + " meals/week",
					"player": p.player.bio.last_name
				})
			
			# Water
			if p.contract.has("water"):
				all_features.append({
					"type": "water",
					"value": p.contract.water,
					"display": "Water: " + str(p.contract.water) + "L/week",
					"player": p.player.bio.last_name
				})
			
			# Ownership share
			if p.contract.has("ownership_share"):
				all_features.append({
					"type": "ownership",
					"value": p.contract.ownership_share,
					"display": "Ownership: " + str(p.contract.ownership_share) + "%",
					"player": p.player.bio.last_name
				})
			
			# Buyout clause
			if p.contract.has("buyout_clause"):
				all_features.append({
					"type": "buyout",
					"value": p.contract.buyout_clause,
					"display": "Buyout: " + p.contract.buyout_clause.capitalize(),
					"player": p.player.bio.last_name
				})
			
			# Housing type
			if p.contract.has("housing"):
				all_features.append({
					"type": "housing",
					"value": p.contract.housing,
					"display": "Housing: " + p.contract.housing.capitalize(),
					"player": p.player.bio.last_name
				})
			
			# Contract length
			if p.contract.has("length"):
				all_features.append({
					"type": "length",
					"value": p.contract.length,
					"display": "Length: " + str(p.contract.length) + " seasons",
					"player": p.player.bio.last_name
				})
			
			# Bonus clause
			if p.contract.has("bonus_clause"):
				all_features.append({
					"type": "bonus",
					"value": p.contract.bonus_clause,
					"display": "Bonus: " + str(p.contract.bonus_clause),
					"player": p.player.bio.last_name
				})
	
	# Shuffle features
	all_features.shuffle()
	
	# Select 6 features, ensuring no more than 2 of the same type
	var selected_features = []
	var feature_type_counts = {}
	
	for feature in all_features:
		var feature_type = feature.type
		var current_count = feature_type_counts.get(feature_type, 0)
		
		if current_count < 2:
			selected_features.append(feature)
			feature_type_counts[feature_type] = current_count + 1
			
			if selected_features.size() >= 6:
				break
	
	# Print selected features for debugging
	print("Selected contract features:")
	for feature in selected_features:
		print("  - ", feature.display, " (from ", feature.player, ")")
	
	return selected_features

func sign_player_pressed(player: Character, num_tokens: int = 0):
	var comparable_features = []
	if all_characters.size() > 3:
		comparables_button_pressed(player)
	
	get_tree().change_scene_to_file("res://negotiate_contract.tscn")

func _on_filter_position_pressed() -> void:
	$PositionsMenu.show()

func _on_filter_style_pressed() -> void:
	$StylesMenu.show()

func _on_filter_traits_pressed(looking_for_players: bool = true) -> void:
	$TraitsMenu.show()
	if looking_for_players:
		$TraitsMenu/StaffRole.hide()
		$TraitsMenu/ContractType.show()
	else:
		$TraitsMenu/StaffRole.show()
		$TraitsMenu/ContractType.hide()

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
				{"display_name": "Overall Rating", "sort_key": "overall"}
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
				{"display_name": "Favorite Food", "sort_key": "cooking_style"},
				{"display_name": "Best League", "sort_key": "best_league"}
			]
		"contract":
			return [
				{"display_name": "First Name", "sort_key": "first_name"},
				{"display_name": "Nickname", "sort_key": "nickname"},
				{"display_name": "Last Name", "sort_key": "last_name"},
				{"display_name": "Contract Type", "sort_key": "contract_type"},
				{"display_name": "Expiry", "sort_key": "expiry"},
				{"display_name": "Length", "sort_key": "length"},
				{"display_name": "Wage", "sort_key": "wage"},
				{"display_name": "Ownership Share", "sort_key": "ownership"}
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
		"styles": [],
		"min_age": 0,
		"max_age": 120,
		"lefty": true,
		"righty": true,
		"full_scout_only": false,
		"attribute_filters": [],
		#TODO: all player styles true
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
	
	# Position filters
	var has_valid_position = false
	for pos in character.player.playable_positions:
		if pos in filters.positions:
			has_valid_position = true
			break
	if not has_valid_position:
		return false
	
	# Position count filters
	var num_positions = character.player.playable_positions.size()
	if num_positions < filters.min_positions or num_positions > filters.max_positions:
		return false
	
	# Age filters
	if character.player.bio.years < filters.min_age or character.player.bio.years > filters.max_age:
		return false
	
	# Handedness filters
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
	if filter_style_button:
		setup_button(filter_style_button, button_size)
	if filter_traits_button:
		setup_button(filter_traits_button, button_size)
	if sort_button:
		setup_button(sort_button, button_size)
	if back_button:
		setup_button(back_button, button_size)
	if view_button:
		setup_button(view_button, button_size)
	if reset_button:
		setup_button(reset_button, button_size)
	
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

func populate_scrollbar():
	for child in scrolling_area.get_children():
		child.queue_free()
	var alternate_color = false
	for character in filtered_characters:
		var row = create_row(character, alternate_color)
		scrolling_area.add_child(row)
		alternate_color = !alternate_color

func create_row(character: Character, dark_row: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	
	var bg = ColorRect.new()
	bg.color = Color(0.3, 0.3, 0.3) if dark_row else Color(0.2, 0.2, 0.2)
	bg.z_index = -1
	row.add_child(bg)
	
	match current_view:
		"default":
			add_default_view_columns(row, character)
		"relative":
			add_relative_view_columns(row, character)
		"personal":
			add_personal_view_columns(row, character)
		"contract":
			add_contract_view_columns(row, character)
		"pitching":
			add_pitching_view_columns(row, character)
	
	var select_button = Button.new()
	select_button.text = "Select"
	select_button.pressed.connect(func(): player_selected(character))
	row.add_child(select_button)
	
	return row

func add_default_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	add_label(row, get_contract_team(character))
	add_label(row, get_contract_type(character))
	add_label(row, get_primary_position(character))
	add_label(row, get_secondary_positions(character))
	add_label(row, str(character.player.bio.years))
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

func add_contract_view_columns(row: HBoxContainer, character: Character):
	add_label(row, character.player.bio.first_name)
	add_label(row, character.player.bio.nickname if character.player.bio.nickname else "-")
	add_label(row, character.player.bio.last_name)
	
	if character.contract:
		add_label(row, get_contract_type(character))
		add_label(row, str(character.contract.seasons_remaining) if character.contract.has("seasons_remaining") else "1")
		add_label(row, str(character.contract.length))
		add_label(row, str(character.contract.salary) + "¢")
		add_label(row, str(character.contract.ownership_share) + "%" if character.contract.has("ownership_share") else "0%")
	else:
		for i in range(5):
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

func add_label(container: HBoxContainer, text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size = Vector2(100, 0)
	container.add_child(label)

func get_contract_team(character: Character) -> String:
	if character.contract and character.contract.has("team"):
		return character.contract.team
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
		child.queue_free()
	var message_container = HBoxContainer.new()
	message_container.custom_minimum_size = Vector2(0, 100)
	message_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var no_results_label = Label.new()
	no_results_label.text = "No players were found matching the search criteria"
	no_results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) #TODO: find a good color
	no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_container.add_child(no_results_label)
	scrolling_area.add_child(message_container)
