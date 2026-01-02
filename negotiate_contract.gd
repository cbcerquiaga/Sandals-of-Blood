extends Control

var character: Character
var player: Player
@onready var popup: PopupMenu = $PopupMenu

var is_tryout_contract: bool
const min_length: int = 1 #1 season contract or 1 game tryout
const max_length: int = 4 #4 season contract or 4 game tryout
const min_salary: int = 0
const max_salary: int = 100000
const min_share: int = 0
const max_share: int = 100 #full team ownership
const min_water: int = 0
const max_water: int = 250 #average modern usa water consumption
const min_food: int = 0
const max_food: int = 42 #3 meals a day and double rations
var player_contract_types = ["tryout", "standard", "tradeable", "franchise"]
var staff_contract_types = ["coach", "scout", "security", "surgeon", "medic", "promoter", "grounds", "equipment", "cook", "accountant", "entourage"]
var housing_types = ["none", "spot", "tent", "car", "shack", "trailer", "room", "cabin", "mansion", "compound"]
var focus_types = ["value", "stability", "flexibility", "satiety", "hydration", "hometown", "housing", "gameday", "travel", "medical", "party", "chill", "win_now", "win_later", "loyalty", "opportunity", "community", "development", "safety", "education", "trade", "farming", "day_life", "night_life", "welfare"]
var bonus_types = ["gp", "win", "goal", "assist", "point", "sack", "partner_sack", "team_sack", "KO", "5hits", "5returns", "5fow", "gf", "clean_sheet"]
var bonus_prizes = ["salary_raise", "cash_payment", "feast"] #permanent raise in salary, one time cash payment, one time food payment
var bonus_values_raise = [1, 2, 3, 4, 5]
var bonus_values_cash = [1, 5, 10, 25, 100] #coin denominations
var bonus_values_feast = [1, 2, 3, 4, 5] #5 meals in one sitting would be pretty crazy
var buyout_types = ["free", "buy50", "buy100", "buy200", "nobuy"] #what it takes to cut the player: nothng, 50% of the money they're still owed, all of the money they're owed, double the money they're owed, or they can't be bought out at all
var promise_types = ["none", "make_captain", "championship", "promotion", "promo_playoff", "no_relegate", "improve_front", "improve_back", "improve_training", "improve_amenity", "improve_party"]
var sell_types = ["experience", "family", "winning", "future", "town", "kids", "fiesta", "adventure", "home", "quiet"]
#no promise, make the player captain, win the league or win a special tournament, move up to the next league (top 2), not get sent down to the lower league, sign or trade for LF/P/RF, sign or trade for LG/K/RG, improve the team's training facilities or coaching staff, improve team's housing or game day, improve team's party situation
var total_family: int = 2 #how many mouths the player has to feed
var true_max_food: int #adjusts max food for family size
var offer_sheet_tokens: int = 0 #0 for free agent, 1 for standard offer sheet, 2 for franchise
var scouting_knowledge: ScoutReport
var comparables = []

var increment_size: Vector2 = Vector2(100, 100) #increment contract details
var change_size: Vector2 = Vector2(300, 100) #size of the literal "change" buttons
var action_size: Vector2 = Vector2(360, 120) #size of the "offer" and "cancel" buttons
var menu_rect_size: Vector2 = Vector2(350, 80) #labels for incrementing and changing

var current_contract_type: String = "standard"
var current_seasons: int = 1
var current_tryout = 1
var current_salary = 0
var current_share = 0
var current_water = 0
var current_food = 0
var current_buyout: String = "free"
var current_sell: String = ""
var current_housing: String = "none"
var current_promise: String = "none"
var current_bonus_type: String = "gp"
var current_bonus_prize: String = "salary_raise"
var current_bonus_value: int = 1
var current_popup_type: String = ""
@onready var season_length = 28 #every league has 8 teams, teams play 2 home and 2 away against all 7 other teams

func _ready():
	debug_default_player()#TODO: Debug only
	true_max_food = max_food * (1 + total_family)
	base_offer()
	arrange()
	setup_popup_theme()
	
	$VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/Decisions/OfferButton.grab_focus()
	
func base_offer():
	#TODO: tailor to player
	#TODO: tailor to team's finances and resources
	#TODO: tailor to scouting knowledge
	current_salary = 45
	current_water = 24
	current_food = 10
	current_share = 1
	current_seasons = 3
	current_contract_type = "standard"
	initial_offer()
	base_offer_ui()
	
func base_offer_ui():
	$VBoxContainer/Bottom/ContractDetails/Water/Label.text = str(current_water) + "L / Week"
	$VBoxContainer/Bottom/ContractDetails/Meals/Label.text = str(current_food) + " Meals / Week"
	$VBoxContainer/Bottom/ContractDetails/Salary/Label.text = str(current_salary) + "¢ / Week"
	update_seasons_label()
	$VBoxContainer/Bottom/ContractDetails/Share/Label.text = str(current_share) + "%"
	
func setup_popup_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "PopupMenu", 46)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2)
	stylebox.border_width_bottom = 4
	stylebox.border_width_left = 4
	stylebox.border_width_right = 4
	stylebox.border_width_top = 4
	stylebox.border_color = Color(0.8, 0.8, 0.8)
	stylebox.corner_radius_top_left = 10
	stylebox.corner_radius_top_right = 10
	stylebox.corner_radius_bottom_right = 10
	stylebox.corner_radius_bottom_left = 10
	stylebox.content_margin_left = 20
	stylebox.content_margin_right = 20
	stylebox.content_margin_top = 15
	stylebox.content_margin_bottom = 15
	theme.set_stylebox("panel", "PopupMenu", stylebox)
	popup.theme = theme

func arrange():
	arrange_portrait_section()
	arrange_top_sections()
	arrange_left_sections()
	arrange_right_sections()
	arrange_knowledge_grid()
	arrange_focuses_grid()
	

func arrange_portrait_section():
	var backRect = $VBoxContainer/Top/PlayerColorRect
	var frontRect = $VBoxContainer/Top/PlayerColorRect/ColorRect
	var portrait = $VBoxContainer/Top/PlayerColorRect/ColorRect/Portrait
	var label = $VBoxContainer/Top/PlayerColorRect/ColorRect/Label
	
	backRect.color = Color.BLACK
	backRect.custom_minimum_size = Vector2(200, 250)
	backRect.size = Vector2(200, 250)
	
	frontRect.color = Color("#585858")
	frontRect.custom_minimum_size = Vector2(180, 230)
	frontRect.size = Vector2(180, 230)
	
	if portrait is TextureRect:
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(200, 200)
	portrait.size = Vector2(200, 200)
	portrait.position = Vector2(-450, 10)
	label.add_theme_font_size_override("font_size", 32)
	label.custom_minimum_size = Vector2(160, 115)
	label.size = Vector2(160, 115)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.y += 140
	
	backRect.position = Vector2(400, backRect.position.y)

func arrange_top_sections():
	var labelRectangles = [$VBoxContainer/Top/Notes1/CompsRect, $VBoxContainer/Top/Notes1/ScoutNotesRect, $VBoxContainer/Top/Notes1/InterestRect, $VBoxContainer/Top/Notes2/TopSkillsRect, $VBoxContainer/Top/Notes2/ThrowsRect, $VBoxContainer/Top/Notes2/PotentialRect]
	var notes = [$VBoxContainer/Top/Notes1/Comps, $VBoxContainer/Top/Notes1/ScoutNotes, $VBoxContainer/Top/Notes1/Interest, $VBoxContainer/Top/Notes2/TopSkills, $VBoxContainer/Top/Notes2/Throws, $VBoxContainer/Top/Notes2/Potential]
	
	for rect in labelRectangles:
		rect.color = Color("#31b563")
		rect.custom_minimum_size = Vector2(300, 80)
		rect.size = Vector2(300, 80)
		
		var child_label = rect.get_node_or_null("Label")
		if child_label:
			child_label.add_theme_font_size_override("font_size", 40)
			child_label.custom_minimum_size = Vector2(300, 80)
			child_label.size = Vector2(300, 80)
			child_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			child_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	for note in notes:
		note.add_theme_font_size_override("font_size", 30)
		note.custom_minimum_size = Vector2(300, 60)
		note.size = Vector2(300, 60)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func arrange_left_sections():
	var left_sections = [$VBoxContainer/Bottom/ContractDetails/Seasons, $VBoxContainer/Bottom/ContractDetails/Salary, $VBoxContainer/Bottom/ContractDetails/Share, $VBoxContainer/Bottom/ContractDetails/Water, $VBoxContainer/Bottom/ContractDetails/Meals]
	
	for section in left_sections:
		var color_rect = section.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.custom_minimum_size = menu_rect_size
			color_rect.size = menu_rect_size
			
			var label = color_rect.get_node_or_null("Label")
			if label:
				label.add_theme_font_size_override("font_size", 50)
				label.custom_minimum_size = menu_rect_size
				label.size = menu_rect_size
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var left_button = section.get_node_or_null("LeftButton")
		var right_button = section.get_node_or_null("RightButton")
		
		if left_button and left_button is TextureButton:
			scale_texture_button(left_button, increment_size)
		if right_button and right_button is TextureButton:
			scale_texture_button(right_button, increment_size)
		
		var section_label = section.get_node_or_null("Label")
		if section_label:
			section_label.add_theme_font_size_override("font_size", 40)
			section_label.custom_minimum_size = menu_rect_size
			section_label.size = menu_rect_size
			section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func arrange_right_sections():
	var right_sections = [$VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/ContractType, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Housing, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Promise, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusPrize, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusValue, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BuyoutValue]
	
	for section in right_sections:
		var color_rect = section.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.custom_minimum_size = menu_rect_size
			color_rect.size = menu_rect_size
			
			var label = color_rect.get_node_or_null("Label")
			if label:
				label.add_theme_font_size_override("font_size", 50)
				label.custom_minimum_size = menu_rect_size
				label.size = menu_rect_size
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var section_label = section.get_node_or_null("Label")
		if section_label:
			section_label.add_theme_font_size_override("font_size", 40)
			section_label.custom_minimum_size = menu_rect_size
			section_label.size = menu_rect_size
			section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var change_button = section.get_node_or_null("ChangeButton")
		if change_button and change_button is TextureButton:
			scale_texture_button(change_button, change_size)
	
	var offer_button = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/Decisions/OfferButton
	var cancel_button = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/Decisions/CancelButton
	
	if offer_button and offer_button is TextureButton:
		scale_texture_button(offer_button, action_size)
	if cancel_button and cancel_button is TextureButton:
		scale_texture_button(cancel_button, action_size)

func scale_texture_button(button: TextureButton, new_size: Vector2):
	var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
	
	for prop in texture_properties:
		var texture = button.get(prop)
		if texture:
			var image = texture.get_image()
			image.resize(int(new_size.x), int(new_size.y))
			button.set(prop, ImageTexture.create_from_image(image))
			
func arrange_knowledge_grid():
	fill_knowledge_headers()
	#fill_knowledge_values()
	var knowledge_labels = [
		$VBoxContainer/Top/Knowledge/Positions,
		$VBoxContainer/Top/Knowledge/Type,
		$VBoxContainer/Top/Knowledge/Potential,
		$VBoxContainer/Top/Knowledge/Professional,
		$VBoxContainer/Top/Knowledge/Hustle,
		$VBoxContainer/Top/Knowledge/Family,
		$VBoxContainer/Top/Knowledge/Gang,
		$VBoxContainer/Top/Knowledge/Job,
		$VBoxContainer/Top/Knowledge/Positions_player,
		$VBoxContainer/Top/Knowledge/Type_player,
		$VBoxContainer/Top/Knowledge/Potential_player,
		$VBoxContainer/Top/Knowledge/Professional_player,
		$VBoxContainer/Top/Knowledge/Hustle_player,
		$VBoxContainer/Top/Knowledge/Family_player,
		$VBoxContainer/Top/Knowledge/Gang_player,
		$VBoxContainer/Top/Knowledge/Job_player
	]
	var label_style = StyleBoxFlat.new()
	label_style.bg_color = Color.TRANSPARENT
	label_style.border_width_left = 5
	label_style.border_width_right = 5
	label_style.border_width_top = 5
	label_style.border_width_bottom = 5
	label_style.border_color = Color.WHITE
	label_style.content_margin_left = 10
	label_style.content_margin_right = 10
	label_style.content_margin_top = 10
	label_style.content_margin_bottom = 10
	
	for label in knowledge_labels:
		if label is Label:
			label.add_theme_font_size_override("font_size", 36)
			label.add_theme_stylebox_override("normal", label_style)
			label.custom_minimum_size = Vector2(250, 50)

	
func fill_knowledge_headers():
	$VBoxContainer/Top/Knowledge/Positions.text = "Positions Played"
	$VBoxContainer/Top/Knowledge/Type.text = "Player Type"
	$VBoxContainer/Top/Knowledge/Potential.text = "Potential"
	$VBoxContainer/Top/Knowledge/Professional.text = "Professionalism"
	$VBoxContainer/Top/Knowledge/Hustle.text = "Hustle"
	$VBoxContainer/Top/Knowledge/Family.text = "Family Size"
	$VBoxContainer/Top/Knowledge/Gang.text = "Gang Affiliations"
	$VBoxContainer/Top/Knowledge/Job.text = "Day Job"
	
func fill_knowledge_values():
	#TODO: Has an extra / in the format
	
	var positions_string = ""
	if player.preferred_position != null:
		positions_string += player.preferred_position
	else:
		player.find_preferred_position()
		positions_string += player.preferred_position
	for position in player.playable_positions:
		if position == player.preferred_position:
			continue
		else:
			positions_string += "/" + position
	$VBoxContainer/Top/Knowledge/Positions_player.text = positions_string
	var style_string
	if player.playStyle:
		style_string = player.playStyle
	else:
		player.calculate_player_type()
		style_string = player.playStyle
	$VBoxContainer/Top/Knowledge/Type_player.text = style_string
	var potential_string
	if scouting_knowledge.info.potential:
		$VBoxContainer/Top/Knowledge/Potential_player.text = str(character.off_attributes.potential)
	else:
		$VBoxContainer/Top/Knowledge/Potential_player.text = "?"
		
	if scouting_knowledge.info.professionalism:
		$VBoxContainer/Top/Knowledge/Professional_player.text = str(character.off_attributes.professionalism)
	else:
		$VBoxContainer/Top/Knowledge/Professional_player.text = "?"
	
	if scouting_knowledge.info.hustle:
		$VBoxContainer/Top/Knowledge/Hustle_player.text = str(character.off_attributes.hustle)
	else:
		$VBoxContainer/Top/Knowledge/Hustle_player.text = "?"
	
	if scouting_knowledge.info.family:
		var family = character.get_family_count()
		total_family = family
		$VBoxContainer/Top/Knowledge/Family_player.text = str(family)
	else:
		$VBoxContainer/Top/Knowledge/Family_player.text = "?"
		total_family = 1
		
	if scouting_knowledge.info.gang:
		$VBoxContainer/Top/Knowledge/Gang_player.text = character.gang_affiliation
	else:
		$VBoxContainer/Top/Knowledge/Gang_player.text = "?"
		
	var job_str = "?"
	if true:
		if character.day_job != "none":
			job_str = "Yes"
		else:
			job_str = "No"
	$VBoxContainer/Top/Knowledge/Job_player.text = job_str
		
	pass
	

	
func arrange_focuses_grid():
	var focus_labels = [$VBoxContainer/Top/Focuses/Focus_header, $VBoxContainer/Top/Focuses/Team_header, $VBoxContainer/Top/Focuses/Want_header, $VBoxContainer/Top/Focuses/Focus1, $VBoxContainer/Top/Focuses/Team1,$VBoxContainer/Top/Focuses/Want1, $VBoxContainer/Top/Focuses/Focus2, $VBoxContainer/Top/Focuses/Team2, $VBoxContainer/Top/Focuses/Want2, $VBoxContainer/Top/Focuses/Focus3, $VBoxContainer/Top/Focuses/Team3, $VBoxContainer/Top/Focuses/Want3, $VBoxContainer/Top/Focuses/Focus4, $VBoxContainer/Top/Focuses/Team4, $VBoxContainer/Top/Focuses/Want4, $VBoxContainer/Top/Focuses/Focus5, $VBoxContainer/Top/Focuses/Team5, $VBoxContainer/Top/Focuses/Want5, $VBoxContainer/Top/Focuses/Focus6, $VBoxContainer/Top/Focuses/Team6, $VBoxContainer/Top/Focuses/Want6, $VBoxContainer/Top/Focuses/Focus7, $VBoxContainer/Top/Focuses/Team7, $VBoxContainer/Top/Focuses/Want7]
	var label_style = StyleBoxFlat.new()
	label_style.bg_color = Color.TRANSPARENT
	label_style.border_width_left = 5
	label_style.border_width_right = 5
	label_style.border_width_top = 5
	label_style.border_width_bottom = 5
	label_style.border_color = Color.WHITE
	label_style.content_margin_left = 10
	label_style.content_margin_right = 10
	label_style.content_margin_top = 10
	label_style.content_margin_bottom = 10
	
	for label in focus_labels:
		if label is Label:
			label.add_theme_font_size_override("font_size", 36)
			label.add_theme_stylebox_override("normal", label_style)
			label.custom_minimum_size = Vector2(250, 50)
	pass

func fill_info():
	$VBoxContainer/Top/PlayerColorRect/ColorRect/Portrait
	#TODO: set portrait from player character
	$VBoxContainer/Top/PlayerColorRect/ColorRect/Label
	#TODO: fill character info:
	#Firstname Lastname
	#Primary Position
	#Ft ' In " Pounds Lbs
	#Age Years Old
	pass
	
func debug_default_player():
	character = Character.new()
	player = Player.new()
	pass

func _on_offer_button_pressed() -> void:
	offer_contract()

func _on_cancel_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sign_players.tscn")
	pass

func less_duration_pressed() -> void:
	if current_seasons > min_length:
		current_seasons -= 1
	update_seasons_label()

func more_duration_pressed() -> void:
	if current_seasons < max_length:
		current_seasons += 1
	update_seasons_label()

func update_seasons_label():
	var string = str(current_seasons)
	if current_contract_type == "tryout":
		if current_seasons == 1:
			string = string + " Game"
		else:
			string = string + " Games"
	else:
		if current_seasons == 1:
			string = string + " Year"
		else:
			string = string + " Years"
	$VBoxContainer/Bottom/ContractDetails/Seasons/Label.text = string

func less_salary_pressed() -> void:
	if current_salary > 0:
		current_salary -= 5
	$VBoxContainer/Bottom/ContractDetails/Salary/Label.text = str(current_salary) + "¢ / Week"

func more_salary_pressed() -> void:
	if current_salary < max_salary:
		current_salary += 5
	$VBoxContainer/Bottom/ContractDetails/Salary/Label.text = str(current_salary) + "¢ / Week"

func less_share_pressed() -> void:
	if current_share > 0:
		current_share -= 1
	$VBoxContainer/Bottom/ContractDetails/Share/Label.text = str(current_share) + "%"

func more_share_pressed() -> void:
	if current_share < max_share:
		current_share += 1
	$VBoxContainer/Bottom/ContractDetails/Share/Label.text = str(current_share) + "%"

func less_water_pressed() -> void:
	if current_water > 0:
		current_water -= 2
	$VBoxContainer/Bottom/ContractDetails/Water/Label.text = str(current_water) + "L / Week"

func more_water_pressed() -> void:
	if current_water < max_water:
		current_water += 2
	$VBoxContainer/Bottom/ContractDetails/Water/Label.text = str(current_water) + "L / Week"

func less_meals_pressed() -> void:
	if current_food > 0:
		current_food -= 1 * (1 + total_family)
	if current_food < 0:
		current_food = 0
	$VBoxContainer/Bottom/ContractDetails/Meals/Label.text = str(current_food) + " Meals / Week"

func more_meals_pressed() -> void:
	if current_food < (true_max_food):
		current_food += 1 * (1 + total_family)
	if current_food > (true_max_food):
		current_food = 0
	$VBoxContainer/Bottom/ContractDetails/Meals/Label.text = str(current_food) + " Meals / Week"

func show_popup_menu(items: Array, popup_type: String, readable_names: Dictionary = {}) -> void:
	popup.clear()
	current_popup_type = popup_type
	
	for i in range(items.size()):
		var item = items[i]
		var display_name = readable_names.get(item, item.capitalize().replace("_", " "))
		popup.add_item(display_name, i)
	popup.popup_centered(Vector2(400, 300))

func _on_popup_menu_id_pressed(id: int) -> void:
	match current_popup_type:
		"contract_type":
			_on_contract_type_selected(id)
		"housing":
			_on_housing_type_selected(id)
		"pitch":
			_on_pitch_selected(id)
		"promise":
			_on_promise_selected(id)
		"bonus_clause":
			_on_bonus_clause_selected(id)
		"bonus_prize":
			_on_bonus_prize_selected(id)
		"bonus_value":
			_on_bonus_value_selected(id)
		"buyout":
			_on_buyout_value_selected(id)

func change_contract_type() -> void:
	var types = player_contract_types if not is_tryout_contract else staff_contract_types
	var readable = {
		"tryout": "Tryout",
		"standard": "Standard",
		"tradeable": "Tradeable",
		"franchise": "Franchise",
		"coach": "Assistant Coach",
		"scout": "Chief Scout",
		"security": "Head of Security",
		"surgeon": "Surgeon",
		"medic": "Medic",
		"promoter": "Promoter",
		"grounds": "Groundskeeper",
		"equipment": "Equipment Manager",
		"cook": "Head Cook",
		"accountant": "Accountant",
		"entourage": "Partier"
	}
	
	show_popup_menu(types, "contract_type", readable)

func _on_contract_type_selected(id: int) -> void:
	var types = player_contract_types if not is_tryout_contract else staff_contract_types
	if id >= 0 and id < types.size():
		current_contract_type = types[id]
		update_contract_type_label()
		update_seasons_label()

func update_contract_type_label() -> void:
	var string
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/ContractType/Label
	match current_contract_type:
		"tryout":
			label.text = "Tryout"
		"standard":
			label.text = "Standard"
		"tradeable":
			label.text = "Tradeable"
		"franchise":
			label.text = "Franchise"
		"coach":
			label.text = "Assistant Coach"
		"scout":
			label.text = "Chief Scout"
		"security":
			label.text = "Head of Security"
		"surgeon":
			label.text = "Surgeon"
		"medic":
			label.text = "Medic"
		"promoter":
			label.text = "Promoter"
		"grounds":
			label.text = "Groundskeeper"
		"equipment":
			label.text = "Equipment Manager"
		"cook":
			label.text = "Head Cook"
		"accountant":
			label.text = "Accountant"
		"entourage":
			label.text = "Partier"

func change_housing_type() -> void:
	var readable = {
		"none": "No Housing",
		"spot": "Sleeping Spot",
		"tent": "Tent",
		"car": "Car",
		"shack": "Shack",
		"trailer": "Trailer",
		"room": "Private Room",
		"cabin": "Cabin",
		"mansion": "Mansion"
	}
	
	show_popup_menu(housing_types, "housing", readable)

func _on_housing_type_selected(id: int) -> void:
	if id >= 0 and id < housing_types.size():
		current_housing = housing_types[id]
		update_housing_type_label()

func update_housing_type_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Housing/Label
	match current_housing:
		"none":
			label.text = "No Housing"
		"spot":
			label.text = "Sleeping Spot"
		"tent":
			label.text = "Tent"
		"car":
			label.text = "Car"
		"shack":
			label.text = "Shack"
		"trailer":
			label.text = "Trailer"
		"room":
			label.text = "Private Room"
		"cabin":
			label.text = "Cabin"
		"mansion":
			label.text = "Mansion"

func change_pitch_offered() -> void:
	var readable = {
		"experience": "Great place to play", #gameday, travel, winning, chill
		"family": "One big family", #loyalty, community, welfare,
		"winning": "Winning culture", #win now, win later, development
		"future": "Bright future", #win later, development, opportunity
		"town": "Great place to live", #trade, farming, day life
		"kids": "Great place to raise a family", #welfare, education, day life
		"fiesta": "Party lifestyle", #party, night life, chill
		"adventure": "It's an Adventure", #travel, good for anti-hometown, party
		"home": "This is home", #hometown, loyalty, safety
		"quiet": "You can relax here", #farming, chill, safety
	}
	
	show_popup_menu(sell_types, "pitch", readable)

func _on_pitch_selected(id: int) -> void:
	if id >= 0 and id < sell_types.size():
		current_sell = sell_types[id]
		update_pitch_label()

func update_pitch_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch/Label
	match current_sell:
		"experience":
			label.text = "Great place to play" #gameday, travel, winning, chill
		"family":
			label.text = "One big family" #loyalty, community, welfare,
		"winning":
			label.text = "Winning culture" #win now, win later, development
		"future":
			label.text = "Bright future" #win later, development, opportunity
		"town": 
			label.text = "Great place to live"#trade, farming, day life
		"kids":
			label.text = "Great place to raise a family" #welfare, education, day life
		"fiesta":
			label.text = "Party lifestyle" #party, night life, chill
		"adventure":
			label.text = "It's an Adventure"#travel, good for anti-hometown, party
		"home":
			label.text = "This is home" #hometown, loyalty, safety
		"quiet":
			label.text = "You can relax here" #farming, chill, safety

func change_promise_offered() -> void:
	var readable = {
		"none": "No Promise",
		"make_captain": "Make Captain",
		"championship": "Win Championship",
		"promotion": "League Promotion",
		"no_relegate": "Avoid Relegation",
		"improve_front": "Improve Frontcourt",
		"improve_back": "Improve Backcourt",
		"improve_training": "Improve Training",
		"improve_amenity": "Improve the Town",
		"improve_party": "Improve Party Scene"
	}
	
	show_popup_menu(promise_types, "promise", readable)

func _on_promise_selected(id: int) -> void:
	if id >= 0 and id < promise_types.size():
		current_promise = promise_types[id]
		update_promise_label()

func update_promise_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Promise/Label
	match current_promise:
		"none":
			label.text = "No Promise"
		"make_captain":
			label.text = "Make Captain"
		"championship":
			label.text = "Win Championship"
		"promotion":
			label.text = "League Promotion"
		"promo_playoff":
			label.text = "Challenge for Promotion"
		"no_relegate":
			label.text = "Avoid Relegation"
		"improve_front":
			label.text = "Improve Frontcourt"
		"improve_back":
			label.text = "Improve Backcourt"
		"improve_training":
			label.text = "Improve Training"
		"improve_amenity":
			label.text = "Improve the Town"
		"improve_party":
			label.text = "Improve Party Scene"

func change_bonus_clause() -> void:
	var readable = {
		"gp": "Games Played",
		"win": "Wins",
		"goal": "Goals",
		"assist": "Assists",
		"point": "Points",
		"sack": "Sacks",
		"partner_sack": "Partner Sacks",
		"team_sack": "Team Sacks",
		"KO": "Knockouts",
		"5hits": "5+ Hits",
		"5returns": "5+ Returns",
		"5fow": "5+ Face-off Wins",
		"gf": "Goals For",
		"clean_sheet": "Clean Sheets"
	}
	
	show_popup_menu(bonus_types, "bonus_clause", readable)

func _on_bonus_clause_selected(id: int) -> void:
	if id >= 0 and id < bonus_types.size():
		current_bonus_type = bonus_types[id]
		update_bonus_clause_label()

func update_bonus_clause_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause/Label
	match current_bonus_type:
		"gp":
			label.text = "Games Played"
		"win":
			label.text = "Wins"
		"goal":
			label.text = "Goals"
		"assist":
			label.text = "Assists"
		"point":
			label.text = "Points"
		"sack":
			label.text = "Sacks"
		"partner_sack":
			label.text = "Partner Sacks"
		"team_sack":
			label.text = "Team Sacks"
		"KO":
			label.text = "Knockouts"
		"5hits":
			label.text = "5+ Hits"
		"5returns":
			label.text = "5+ Returns"
		"5fow":
			label.text = "5+ Face-off Wins"
		"gf":
			label.text = "Goals For"
		"clean_sheet":
			label.text = "Clean Sheets"

func change_bonus_prize() -> void:
	var readable = {
		"salary_raise": "Salary Raise",
		"cash_payment": "Cash Payment",
		"feast": "Feast"
	}
	
	show_popup_menu(bonus_prizes, "bonus_prize", readable)

func _on_bonus_prize_selected(id: int) -> void:
	if id >= 0 and id < bonus_prizes.size():
		current_bonus_prize = bonus_prizes[id]
		match current_bonus_prize:
			"salary_raise":
				current_bonus_value = bonus_values_raise[0]
			"cash_payment":
				current_bonus_value = bonus_values_cash[0]
			"feast":
				current_bonus_value = bonus_values_feast[0]
		update_bonus_prize_label()
		update_bonus_value_label()

func update_bonus_prize_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusPrize/Label
	match current_bonus_prize:
		"salary_raise":
			label.text = "Salary Raise"
		"cash_payment":
			label.text = "Cash Payment"
		"feast":
			label.text = "Feast"

func change_bonus_value() -> void:
	var values: Array
	var readable = {}
	
	match current_bonus_prize:
		"salary_raise":
			values = bonus_values_raise
			for val in values:
				readable[str(val)] = "+%d¢/Week" % val
		"cash_payment":
			values = bonus_values_cash
			for val in values:
				readable[str(val)] = "%d¢ Payment" % val
		"feast":
			values = bonus_values_feast
			for val in values:
				var meal_text = "Meal" if val == 1 else "Meals"
				readable[str(val)] = "%d %s" % [val, meal_text]
	
	var string_values: Array = []
	for val in values:
		string_values.append(str(val))
	
	show_popup_menu(string_values, "bonus_value", readable)

func _on_bonus_value_selected(id: int) -> void:
	var values: Array
	match current_bonus_prize:
		"salary_raise":
			values = bonus_values_raise
		"cash_payment":
			values = bonus_values_cash
		"feast":
			values = bonus_values_feast
	
	if id >= 0 and id < values.size():
		current_bonus_value = values[id]
		update_bonus_value_label()

func update_bonus_value_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusValue/Label
	match current_bonus_prize:
		"salary_raise":
			label.text = "+%d¢/Week" % current_bonus_value
		"cash_payment":
			label.text = "%d¢ Payment" % current_bonus_value
		"feast":
			var meal_text = "Meal" if current_bonus_value == 1 else "Meals"
			label.text = "%d %s" % [current_bonus_value, meal_text]

func _on_buyout_button_pressed() -> void:
	change_buyout_value()

func change_buyout_value() -> void:
	var readable = {
		"free": "Cut for Free",
		"buy50": "Buyout Half Owed",
		"buy100": "Buyout All Owed",
		"buy200": "Buyout Double Owed",
		"nobuy": "Guaranteed Contract"
	}
	
	show_popup_menu(buyout_types, "buyout", readable)

func _on_buyout_value_selected(id: int) -> void:
	if id >= 0 and id < buyout_types.size():
		current_buyout = buyout_types[id]
		update_buyout_value_label()

func update_buyout_value_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BuyoutValue/Label
	match current_buyout:
		"free":
			label.text = "Cut for Free"
		"buy50":
			label.text = "Buyout Half Owed"
		"buy100":
			label.text = "Buyout All Owed"
		"buy200":
			label.text = "Buyout Double Owed"
		"nobuy":
			label.text = "Guaranteed Contract"
	

func get_proper_position_name(string: String) -> String:
	match string:
		"K":
			return "Goalkeeper"
		"LG", "RG":
			return "Guard"
		"LF", "RF":
			return "Forward"
		"P":
			return "Pitcher"
	return ""

func open_with_character(new_character: Character, tokens: int, report: ScoutReport, comps = []):
	character = new_character
	player = character.player
	offer_sheet_tokens = tokens
	scouting_knowledge = report
	comparables = comps
	#Update family size for food calculations
	total_family = character.get_family_count()
	true_max_food = max_food * (1 + total_family)
	populate_imported_data(character)
	#base_offer()


func populate_imported_data(character: Character):
	populate_bio_info()
	populate_comparables()
	populate_focuses()
	populate_potential()
	populate_scout_notes()
	populate_scout_notes()
	fill_knowledge_values()
	
func populate_bio_info():
	var string = character.player.bio.first_name + "\n" + character.player.bio.last_name + "\n"
	string = string + get_proper_position_name(character.player.preferred_position) + "\n"
	string = string + str(character.player.bio.feet) + "\'" + str(character.player.bio.inches) + "\"" + " " + str(character.player.bio.pounds) + "lbs" + "\n"
	string = string + str(character.player.bio.years) + " Years Old"
	$VBoxContainer/Top/PlayerColorRect/ColorRect/Label.text = string
	$VBoxContainer/Top/PlayerColorRect/ColorRect/Portrait.texture = load(character.player.portrait)
	pass
	
func populate_scout_notes():
	var scout_notes_str = ""
	if scouting_knowledge.percentage == 0:
		$VBoxContainer/Top/Notes1/ScoutNotes.text = "Not Scouted"
		return
	var notable_attributes = pick_notable_attributes()
	for notable in notable_attributes:
		match notable:
			"positivity":
				if character.off_attributes.positivity < 20:
					scout_notes_str += "Does not find joy" + "\n"
				elif character.off_attributes.positivity < 40:
					scout_notes_str += "Not the most excitable" + "\n"
				elif character.off_attributes.positivity < 60:
					scout_notes_str += "Healthy amount of optimism" + "\n"
				elif character.off_attributes.positivity < 80:
					scout_notes_str += "Brings a positive energy" + "\n"
				elif character.off_attributes.positivity < 95:
					scout_notes_str += "Very positive energy" + "\n"
				else: #95+
					scout_notes_str += "Oozes positivity" + "\n"
			"negativity":
				if character.off_attributes.negativity < 20:
					scout_notes_str += "Goes with the flow" + "\n"
				elif character.off_attributes.negativity < 40:
					scout_notes_str += "Doesn't throw chairs when the team loses" + "\n"
				elif character.off_attributes.negativity < 60:
					scout_notes_str += "Hates losing" + "\n"
				elif character.off_attributes.negativity < 80:
					scout_notes_str += "Really hates losing" + "\n"
				elif character.off_attributes.negativity < 95:
					scout_notes_str += "Nobody hates losing more" + "\n"
				else: #95+
					scout_notes_str += "Has diagnosable depression" + "\n"
			"influence":
				if character.off_attributes.influence < 20:
					scout_notes_str += "Very introverted" + "\n"
				elif character.off_attributes.influence < 40:
					match character.gender:
						"m":
							scout_notes_str += "Keeps to himself" + "\n"
						"f":
							scout_notes_str += "Keeps to herself" + "\n"
						"i":
							scout_notes_str += "Keeps to themselves" + "\n"
				elif character.off_attributes.influence < 60:
					scout_notes_str += "Likes to be a part of the team" + "\n"
				elif character.off_attributes.influence < 80:
					scout_notes_str += "Attitude is infections" + "\n"
				elif character.off_attributes.influence < 95:
					scout_notes_str += "Locker room presence" + "\n"
				else: #95+
					scout_notes_str += "A leader in the locker room" + "\n"
			"promiscuity": 
				var hiton = ""
				if character.attracted.m & !character.attracted.f:
					var rand = randi_range(0,2)
					match rand:
						0:
							hiton = "dude"
						1:
							hiton = "hairy twink"
						2:
							hiton = "thick daddy"
						3:
							hiton = "B-league left guard"
				elif character.attracted.f & !character.attracted.m:
					var rand = randi_range(0,3)
					match rand:
						0:
							hiton = "chick"
						1:
							hiton = "muscle mommy"
						2:
							hiton = "bad, bad, bitch"
						3:
							hiton = "warlord's daughter"
				else: #non-gendered hitons
					var rand = randi_range(0,3)
					match rand:
						0:
							hiton = "hottie"
						1:
							hiton = "serf"
						2:
							hiton = "prostitute"
						3:
							hiton = "ball babe"
				
				if character.off_attributes.promiscuity < 20:
					scout_notes_str += "Monogamous" + "\n"
				elif character.off_attributes.promiscuity < 40:
					scout_notes_str += "Not a prude" + "\n"
				elif character.off_attributes.promiscuity < 60:
					scout_notes_str += "Known to like a " + hiton + "\n"
				elif character.off_attributes.promiscuity < 80:
					scout_notes_str += "Always has some new " + hiton + " around" + "\n"
				elif character.off_attributes.promiscuity < 95:
					scout_notes_str += "Has too many " + hiton + "s around all the time" + "\n"
				else: #95+
					scout_notes_str += "Certified " + hiton + " freak" + "\n"
			"loyalty": 
				if character.off_attributes.loyalty < 20:
					scout_notes_str += "Mercenary" + "\n"
				elif character.off_attributes.loyalty < 40:
					scout_notes_str += "Will sign with another team if the contract is good" + "\n"
				elif character.off_attributes.influence < 60:
					scout_notes_str += "Doesn't like moving teams" + "\n"
				elif character.off_attributes.influence < 80:
					scout_notes_str += "Loves to be on one team for a long time" + "\n"
				elif character.off_attributes.influence < 95:
					scout_notes_str += "Wants to have a one-team career" + "\n"
				else: #95+
					scout_notes_str += "Bleeds team colors" + "\n"
			"love_of_the_game":
				if character.off_attributes.love_of_the_game < 20:
					scout_notes_str += "Secretly dislikes ball" + "\n"
				elif character.off_attributes.love_of_the_game < 40:
					scout_notes_str += "Love-hate relationship with the game" + "\n"
				elif character.off_attributes.love_of_the_game < 60:
					scout_notes_str += "Loves the game" + "\n"
				elif character.off_attributes.love_of_the_game < 80:
					scout_notes_str += "Student of the game" + "\n"
				elif character.off_attributes.love_of_the_game < 95:
					scout_notes_str += "Eats, sleeps, and breathes ball" + "\n"
				else: #95+
					scout_notes_str += "Loves ball more than life itself" + "\n"
			"professionalism":
				if character.off_attributes.professionalism < 20:
					scout_notes_str += "Known to go missing for a few days at a time" + "\n"
				elif character.off_attributes.professionalism < 40:
					scout_notes_str += "Late more often than not" + "\n"
				elif character.off_attributes.professionalism < 60:
					scout_notes_str += "Not late too often" + "\n"
				elif character.off_attributes.professionalism < 80:
					scout_notes_str += "Usually on time" + "\n"
				elif character.off_attributes.professionalism < 95:
					scout_notes_str += "Almost always on time" + "\n"
				else: #95+
					scout_notes_str += "Has never been late before" + "\n"
			"partying":
				if character.off_attributes.partying < 20:
					scout_notes_str += "Likes to go to bed early" + "\n"
				elif character.off_attributes.partying < 40:
					scout_notes_str += "Finds excuses to leave parties early" + "\n"
				elif character.off_attributes.partying < 60:
					scout_notes_str += "Likes to party" + "\n"
				elif character.off_attributes.partying < 80:
					scout_notes_str += "Really likes to party" + "\n"
				elif character.off_attributes.partying < 95:
					scout_notes_str += "Life of the party" + "\n"
				else: #95+
					scout_notes_str += "Middle name is \"Party\"" + "\n"
			"potential":
				if character.off_attributes.potential < 20:
					scout_notes_str += "Has no chance of ever becoming a successful baller" + "\n"
				elif character.off_attributes.potential < 40:
					scout_notes_str += "Not cut our for professional ball" + "\n"
				elif character.off_attributes.potential < 60:
					scout_notes_str += "Low ceiling" + "\n"
				elif character.off_attributes.potential < 80:
					scout_notes_str += "Could have a good career" + "\n"
				elif character.off_attributes.potential < 95:
					scout_notes_str += "High ceiling" + "\n"
				else: #95+
					scout_notes_str += "Could be one of the greats" + "\n"
			"hustle":
				if character.off_attributes.hustle < 20:
					scout_notes_str += "Genuinely lazy" + "\n"
				elif character.off_attributes.hustle < 40:
					scout_notes_str += "Doesn't want to do what it takes" + "\n"
				elif character.off_attributes.hustle < 60:
					scout_notes_str += "Has a little juice" + "\n"
				elif character.off_attributes.hustle < 80:
					scout_notes_str += "Definitely has the juice" + "\n"
				elif character.off_attributes.hustle < 95:
					match character.gender:
						"m":
							scout_notes_str += "Has that dawg in him" + "\n"
						"f":
							scout_notes_str += "Has that dawg in her" + "\n"
						"i":
							scout_notes_str += "Has that dawg in them" + "\n"
				else: #95+
					scout_notes_str += "The hardest worker I have ever seen" + "\n"
			"hardiness":
				if character.off_attributes.hardiness < 20:
					scout_notes_str += "Needs a fainting couch for road trips" + "\n"
				elif character.off_attributes.hardiness < 40:
					scout_notes_str += "Has the constitution of a dry leaf" + "\n"
				elif character.off_attributes.hardiness < 60:
					scout_notes_str += "Could struggle with the rigors of a long season" + "\n"
				elif character.off_attributes.hardiness < 80:
					scout_notes_str += "Doesn't get sick much" + "\n"
				elif character.off_attributes.hardiness < 95:
					match character.gender:
						"m":
							scout_notes_str += "A pretty sturdy sonofabitch" + "\n"
						"f":
							scout_notes_str += "A pretty sturdy bitch" + "\n"
						"i":
							scout_notes_str += "A pretty sturdy fucker" + "\n"
				else: #95+
					scout_notes_str += "Could survive off of eating broken glass" + "\n"
			"combat":
				if character.off_attributes.combat < 20:
					scout_notes_str += "Has no survival instincts whatsoever" + "\n"
				elif character.off_attributes.combat < 40:
					scout_notes_str += "Liable to get killed if the team bus gets raided" + "\n"
				elif character.off_attributes.combat < 60:
					scout_notes_str += "Knows how to take cover" + "\n"
				elif character.off_attributes.combat < 80:
					scout_notes_str += "Knows which end of an iron to point" + "\n"
				elif character.off_attributes.combat < 95:
					scout_notes_str += "Once killed a man" + "\n"
				else: #95+
					scout_notes_str += "Does not need security escort" + "\n"
		$VBoxContainer/Top/Notes1/ScoutNotes.text = scout_notes_str

func pick_notable_attributes():
	#TODO: identify values which are very high, very low, or relatively high or low compared to the rest of the character's off_attributes
	
	return ["professionalism", "hustle", "partying"] #TODO: populate with the 3 most notable values from the character

func populate_comparables():
	var string = "No Known Comparables"

	if scouting_knowledge and scouting_knowledge.info.comparables and comparables.size() > 0:
		#Group features by player
		var players_data = {}
		
		for feature in comparables:
			var player_name = feature[4]  #Index 4 is player name
			var similarity = feature[0]    #Index 0 is similarity score
			var display_text = feature[3]  #Index 3 is display text
			
			if not players_data.has(player_name):
				players_data[player_name] = {
					"similarity": similarity,
					"features": []
				}
			
			players_data[player_name]["features"].append(display_text)
		
		#Build the display string
		string = ""
		var player_names = players_data.keys()
		for i in range(player_names.size()):
			var player_name = player_names[i]
			var player_info = players_data[player_name]
			var similarity_percent = int(player_info["similarity"])
			
			#Add player line: Name [XX%] Feature1 Feature2
			string += player_name + " [" + str(similarity_percent) + "%]"
			
			#Add up to 2 features on the same line
			for j in range(min(2, player_info["features"].size())):
				string += " " + player_info["features"][j]
			
			#Add newline if not the last player
			if i < player_names.size() - 1:
				string += "\n"
	
	$VBoxContainer/Top/Notes1/Comps.text = string

func populate_top_skills():
	var skill_1 = ""
	var att_1 = 0
	var skill_2 = ""
	var att_2 = 0
	var skill_3 = ""
	var att_3 = 0
	for attribute in player.attributes:
		if player.attributes[attribute] > att_1:
			att_3 = att_2
			skill_3 = skill_2
			att_2 = att_1
			skill_2 = skill_1
			att_1 = player.attributes[attribute]
			skill_1 = attribute
		elif player.attributes[attribute] > att_2:
			att_3 = att_2
			skill_3 = skill_2
			att_2 = player.attributes[attribute]
			skill_2 = attribute
		elif player.attributes[attribute] > att_3:
			att_3 = player.attributes[attribute]
			skill_3 = attribute
	var skills = [skill_1, skill_2, skill_3]
	for skill in skills:
		if skill == "power":
			skill = "Strength"
		elif skill == "shooting":
			skill = "Striking"
		else:
			skill = skill.capitalize()
	$VBoxContainer/Top/Notes2/TopSkills.text = skills[0] + " " + str(att_1) + "\n" + skills[1] + " " + str(att_2) + "\n" + skills[2] + " " + str(att_3) + "\n"

func populate_throws():
	var throws_string = ""
	if player.special_pitch_names:
		for pitch in player.special_pitch_names:
			if pitch.length() > 0:
				throws_string += pitch.capitalize()
			else:
				throws_string += "None"
			throws_string += "\n"
	pass
	
func populate_potential():
	var body_type = ""
	var true_height = player.bio.feet * 12 + player.bio.inches
	var newtons = player.bio.pounds / true_height
	if newtons > 3: 
		body_type = "Bulky Frame. Builds strength and balance."
	elif newtons > 2.5:
		body_type = "Moderate frame. No bonuses."
	else:
		body_type = "Wiry Frame. Builds speed and endurance."
	$VBoxContainer/Top/Notes2/Potential.text = body_type
	
func populate_focuses():
	if scouting_knowledge.info.key_focus:
		var key_focus = character.get_key_focus()
		var team_value = CareerFranchise.get_contract_focus_value(key_focus)
		var want_value = character.contract_focuses[key_focus]
		$VBoxContainer/Top/Focuses/Focus1.text = pretty_focus_name(key_focus)
		$VBoxContainer/Top/Focuses/Team1.text = get_letter_value(team_value)
		$VBoxContainer/Top/Focuses/Want1.text = get_letter_value(want_value)
	else:
		$VBoxContainer/Top/Focuses/Focus1.text = "?"
		$VBoxContainer/Top/Focuses/Team1.text = "?"
		$VBoxContainer/Top/Focuses/Want1.text = "?"
	
	if scouting_knowledge.info.secondary_focus:
		var focus2 = character.get_nth_focus(1)
		var focus3 = character.get_nth_focus(2)
		var focus4 = character.get_nth_focus(3)
		
		if focus2:
			var team_value2 = CareerFranchise.get_contract_focus_value(focus2)
			var want_value2 = character.contract_focuses[focus2]
			$VBoxContainer/Top/Focuses/Focus2.text = pretty_focus_name(focus2)
			$VBoxContainer/Top/Focuses/Team2.text = get_letter_value(team_value2)
			$VBoxContainer/Top/Focuses/Want2.text = get_letter_value(want_value2)
		else:
			$VBoxContainer/Top/Focuses/Focus2.text = "?"
			$VBoxContainer/Top/Focuses/Team2.text = "?"
			$VBoxContainer/Top/Focuses/Want2.text = "?"
		
		if focus3:
			var team_value3 = CareerFranchise.get_contract_focus_value(focus3)
			var want_value3 = character.contract_focuses[focus3]
			$VBoxContainer/Top/Focuses/Focus3.text = pretty_focus_name(focus3)
			$VBoxContainer/Top/Focuses/Team3.text = get_letter_value(team_value3)
			$VBoxContainer/Top/Focuses/Want3.text = get_letter_value(want_value3)
		else:
			$VBoxContainer/Top/Focuses/Focus3.text = "?"
			$VBoxContainer/Top/Focuses/Team3.text = "?"
			$VBoxContainer/Top/Focuses/Want3.text = "?"
		
		if focus4:
			var team_value4 = CareerFranchise.get_contract_focus_value(focus4)
			var want_value4 = character.contract_focuses[focus4]
			$VBoxContainer/Top/Focuses/Focus4.text = pretty_focus_name(focus4)
			$VBoxContainer/Top/Focuses/Team4.text = get_letter_value(team_value4)
			$VBoxContainer/Top/Focuses/Want4.text = get_letter_value(want_value4)
		else:
			$VBoxContainer/Top/Focuses/Focus4.text = "?"
			$VBoxContainer/Top/Focuses/Team4.text = "?"
			$VBoxContainer/Top/Focuses/Want4.text = "?"
	else:
		$VBoxContainer/Top/Focuses/Focus2.text = "?"
		$VBoxContainer/Top/Focuses/Team2.text = "?"
		$VBoxContainer/Top/Focuses/Want2.text = "?"
		$VBoxContainer/Top/Focuses/Focus3.text = "?"
		$VBoxContainer/Top/Focuses/Team3.text = "?"
		$VBoxContainer/Top/Focuses/Want3.text = "?"
		$VBoxContainer/Top/Focuses/Focus4.text = "?"
		$VBoxContainer/Top/Focuses/Team4.text = "?"
		$VBoxContainer/Top/Focuses/Want4.text = "?"
	
	if scouting_knowledge.info.tertiary_focus:
		var focus5 = character.get_nth_focus(4)
		var focus6 = character.get_nth_focus(5)
		var focus7 = character.get_nth_focus(6)
		
		if focus5:
			var team_value5 = CareerFranchise.get_contract_focus_value(focus5)
			var want_value5 = character.contract_focuses[focus5]
			$VBoxContainer/Top/Focuses/Focus5.text = pretty_focus_name(focus5)
			$VBoxContainer/Top/Focuses/Team5.text = get_letter_value(team_value5)
			$VBoxContainer/Top/Focuses/Want5.text = get_letter_value(want_value5)
		else:
			$VBoxContainer/Top/Focuses/Focus5.text = "?"
			$VBoxContainer/Top/Focuses/Team5.text = "?"
			$VBoxContainer/Top/Focuses/Want5.text = "?"
		
		if focus6:
			var team_value6 = CareerFranchise.get_contract_focus_value(focus6)
			var want_value6 = character.contract_focuses[focus6]
			$VBoxContainer/Top/Focuses/Focus6.text = pretty_focus_name(focus6)
			$VBoxContainer/Top/Focuses/Team6.text = get_letter_value(team_value6)
			$VBoxContainer/Top/Focuses/Want6.text = get_letter_value(want_value6)
		else:
			$VBoxContainer/Top/Focuses/Focus6.text = "?"
			$VBoxContainer/Top/Focuses/Team6.text = "?"
			$VBoxContainer/Top/Focuses/Want6.text = "?"
		
		if focus7:
			var team_value7 = CareerFranchise.get_contract_focus_value(focus7)
			var want_value7 = character.contract_focuses[focus7]
			$VBoxContainer/Top/Focuses/Focus7.text = pretty_focus_name(focus7)
			$VBoxContainer/Top/Focuses/Team7.text = get_letter_value(team_value7)
			$VBoxContainer/Top/Focuses/Want7.text = get_letter_value(want_value7)
		else:
			$VBoxContainer/Top/Focuses/Focus7.text = "?"
			$VBoxContainer/Top/Focuses/Team7.text = "?"
			$VBoxContainer/Top/Focuses/Want7.text = "?"
	else:
		$VBoxContainer/Top/Focuses/Focus5.text = "?"
		$VBoxContainer/Top/Focuses/Team5.text = "?"
		$VBoxContainer/Top/Focuses/Want5.text = "?"
		$VBoxContainer/Top/Focuses/Focus6.text = "?"
		$VBoxContainer/Top/Focuses/Team6.text = "?"
		$VBoxContainer/Top/Focuses/Want6.text = "?"
		$VBoxContainer/Top/Focuses/Focus7.text = "?"
		$VBoxContainer/Top/Focuses/Team7.text = "?"
		$VBoxContainer/Top/Focuses/Want7.text = "?"

func pretty_focus_name(focus: String) -> String:
	match focus:
		"satiety":
			return "Food Security"
		"hydration":
			return "Water Access"
		"hometown":
			return "Proximity to Home"
		"housing":
			return "Preferred Housing"
		"gameday":
			return "Game Day Experience"
		"travel":
			return "Quality of Travel"
		"medical":
			return "Medical Care"
		"party":
			return "Post-win Ragers"
		"chill":
			return "Chilling with Teammates"
		"win_now":
			return "Win Now"
		"win_later":
			return "Future Success"
		"loyalty":
			return "Loyalty to Players"
		"opportunity":
			return "Career Opportunity"
		"community":
			return "Community Involvement"
		"development":
			return "Player Development"
		"safety":
			return "Safety"
		"education":
			return "Education"
		"trade":
			return "Economy"
		"farming":
			return "Farming"
		"day_life":
			return "Day Life"
		"night_life":
			return "Night Life"
		"welfare":
			return "Welfare System"
		_:
			return focus.capitalize()

func get_letter_value(grade: float):
	if grade < 0.7:
		return "F"
	elif grade < 1.0:
		return "D-"
	elif grade < 1.3:
		return "D"
	elif grade < 1.7:
		return "D+"
	elif grade < 2.0:
		return "C-"
	elif grade < 2.3:
		return "C"
	elif grade < 2.7:
		return "C+"
	elif grade < 3.0:
		return "B-"
	elif grade < 3.3:
		return "B"
	elif grade < 3.7:
		return "B+"
	elif grade < 4.0:
		return "A-"
	elif grade < 4.3:
		return "A+"
	else:
		return "A++"

func get_key_value(key):
	match key:
		"value":
			return get_value_value()
		"flexibility":
			return get_flex_value()
		"stability":
			return get_stability_value()

func get_value_value():
	var salary_total = 0 #between 0 and 110,000 (probably)
	var max_bonus = 0
	var believed_bonus = 0
	var share_value = 0
	var bonus_wight = 0
	if current_contract_type == "tryout":
		salary_total = current_salary * current_tryout
	else:
		salary_total = current_salary * current_seasons * season_length
	
	max_bonus = get_max_bonus() * current_seasons
	believed_bonus = max_bonus * player.get_buffed_attribute("confidence")/100
	
	
	var salary_weight = float(salary_total)/float(salary_total + max_bonus + share_value)
	var share_weight = float(share_value)/float(salary_total + max_bonus + share_value)
	var bonus_weight = float(believed_bonus)/float(salary_total + max_bonus + share_value)
	var weighted_value = salary_total * salary_weight + max_bonus * bonus_weight/2 + believed_bonus * bonus_weight/2

	var previous_contract_value = get_previous_contract_value()
	var roster_equivalent = get_roster_equivalent()
	var player_progression = get_player_progression_state()
	
	var min_expected = 0
	match player_progression: #TODO: determine value rating based on this contract's weighted value, the previous contract, and the player progression state
		4: #player expects a raise over the record contract
			min_expected = GameWorld.max_world_contract_value * 1.05
			pass
		3: #player expects to be around the current top contract
			min_expected = GameWorld.max_world_contract_value * 0.9 
			pass
		2: #player expects a big raise
			if previous_contract_value > 0:
				min_expected = previous_contract_value * 2
			else:
				min_expected = get_roster_equivalent()
		1: #player expects a raise
			if previous_contract_value > 0:
				min_expected = previous_contract_value * 1.2
			else:
				min_expected = get_roster_equivalent()
		0: #player expects roughly their previous contract
			if previous_contract_value > 0:
				min_expected = previous_contract_value
			else:
				min_expected = get_roster_equivalent()
		-1: #player knows they're getting a pay cut
			if previous_contract_value > 0:
				min_expected = previous_contract_value * 0.8
			else:
				min_expected = get_roster_equivalent() * 0.8
				pass
		-2:
			#player knows they are getting less contract than last time
			if previous_contract_value > 0:
				min_expected = previous_contract_value * 0.5
			else:
				min_expected = get_roster_equivalent() * 0.5
	var equivalent = get_roster_equivalent()
	var star_rating = 0
	if weighted_value > min_expected + equivalent:
		star_rating = 5 #too good to be true!
	elif weighted_value > min_expected and weighted_value > equivalent:
		star_rating = 4
	elif (weighted_value < equivalent or weighted_value < min_expected) and (weighted_value >= equivalent or weighted_value >= min_expected):
		star_rating = 3
	elif weighted_value/equivalent > 0.7:
		star_rating = 2
	elif weighted_value/equivalent <= 0.7:
		star_rating = 1 #not great
	if current_buyout == "free":
		star_rating -= 0.5
	elif current_buyout == "buy200":
		star_rating += 0.5
	if character.day_job_pay > current_salary:
		star_rating = star_rating * 0.8
	return star_rating
	
func get_flex_value(): #0 to 5.5
	var flex_value = 0
	match current_seasons:
		4:
			flex_value = 1
		3:
			flex_value = 2
		2:
			flex_value = 3
		1:
			flex_value = 4
	match current_bonus_type:
		"free":
			flex_value += 1
		"buy50":
			flex_value += 0.5
		"buy100":
			flex_value += 0.25
		"buy200":
			flex_value -= 0.5
		"nobuy":
			flex_value -= 1
	
	if current_contract_type == "franchise": #getting franchise tag makes it harder to move to a new team
		flex_value = flex_value / 2
	elif current_contract_type == "tradeable":
		flex_value = flex_value + 0.5
	elif current_contract_type == "tryout":
		return 2 #technically flexible but not actually desirable
	return flex_value

func get_stability_value():
	var stability_value = 0
	if current_contract_type != "tryout":
		match current_seasons:
			4:
				stability_value = 4
			3:
				stability_value = 3
			2:
				stability_value = 2
			1:
				stability_value = 1
	match current_bonus_type:
		"free":
			stability_value -= 1
		"buy50":
			stability_value -= 0.5
		"buy100":
			stability_value
		"buy200":
			stability_value += 0.5
		"nobuy":
			stability_value += 1
	if current_share > 0:
		stability_value += 1
	if current_contract_type == "franchise":
		stability_value += 0.5
	elif current_contract_type == "tradeable":
		stability_value = stability_value/2
	return stability_value
	
func get_max_bonus():
	var max_possible = 0
	match current_bonus_type:
		"gp":
			max_possible = season_length
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"win":
			max_possible = season_length
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"goal":
			max_possible = season_length * 4
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(season_length)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"assist":
			max_possible = season_length * 3
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"point":
			max_possible = season_length * 7 #would require a one man team but doable
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"sack":
			max_possible = season_length * 3
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"partner_sack":
			max_possible = season_length * 3
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"team_sack":
			max_possible = season_length * 6
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"KO":
			max_possible = season_length * 2 #would be pretty spectacular, but technically possible
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"5hits":
			max_possible = int(season_length * 0.75)
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"5returns":
			max_possible = int(season_length * 0.9) #90% return rate would be good
			if !player.playable_positions.contains("K"):
				max_possible = 0 #not a keeper, can't get any
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else: return 0 #feast prize or not a keeper
		"5fow":
			max_possible = 5 #pretty rare achievement
			if !player.playable_positions.contains("P"):
				max_possible = 0 #not a pitcher, can't get any
				if current_bonus_prize == "salary_raise":
					return get_raise_bonus(max_possible)
				elif current_bonus_prize == "cash_prize":
					return current_bonus_value * max_possible
			return 0 #feast prize or not a pitcher
		"gf":
			max_possible = 7 * season_length #assumes a perfect record
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
		"clean_sheet":
			max_possible = season_length
			if current_bonus_prize == "salary_raise":
				return get_raise_bonus(max_possible)
			elif current_bonus_prize == "cash_prize":
				return current_bonus_value * max_possible
			else:
				return 0 #feast prize
	
func get_raise_bonus(max_raises_season: int):
	var modded_salary = current_salary
	for raise in max_raises_season:
		modded_salary = current_salary  + current_bonus_value
	var diff = modded_salary - current_salary
	return diff
	
func get_max_share_bonus(max_shares_season: int):
	var modded_share = current_share
	for option in max_shares_season:
		modded_share = current_salary  + current_bonus_value
	var diff = get_share_value(modded_share) - get_share_value(current_share)
	return diff
	
func get_previous_contract_value():
	var previous_contract = character.previous_contract
	if previous_contract:
		#TODO: get the weighted value of the previous contract
		return 0
	else:
		return 0
	
func get_player_progression_state():
	#4 is for hall of fame level player, 3 is for MVP level
	#1 for going up, 2 for big breakout year
	#0 for same
	#-1 for declining, -2 for desperate
	return 0
	
func get_roster_equivalent():
	if !CareerFranchise or !CareerFranchise.contracts:
		return 0
	var position_depth = []
	var current_player_ovr = player.get_best_overall()
	for contract_data in CareerFranchise.contracts.values():
		if contract_data.size() < 2:
			continue
		var roster_character = contract_data[0] as Character
		var roster_player = roster_character.player as Player
		var roster_contract = contract_data[1] as Contract
		var can_play_same_position = false
		for pos in player.playable_positions:
			if pos in roster_player.playable_positions:
				can_play_same_position = true
				break
		if !can_play_same_position:
			continue
		var contract_value = 0
		if roster_contract.type != "tryout":
			contract_value = roster_contract.current_salary * roster_contract.original_seasons * season_length
		else:
			contract_value = roster_contract.current_salary * roster_contract.original_tryout
		if roster_contract.current_share > 0:
			contract_value += get_share_value(roster_contract.current_share)
		var max_bonus = 0
		if roster_contract.current_bonus_type == "gp":
			max_bonus = season_length
		elif roster_contract.current_bonus_type == "win":
			max_bonus = season_length
		elif roster_contract.current_bonus_type == "goal":
			max_bonus = season_length * 4
		elif roster_contract.current_bonus_type == "assist":
			max_bonus = season_length * 3
		elif roster_contract.current_bonus_type == "point":
			max_bonus = season_length * 7
		elif roster_contract.current_bonus_type == "sack":
			max_bonus = season_length * 3
		elif roster_contract.current_bonus_type == "partner_sack":
			max_bonus = season_length * 3
		elif roster_contract.current_bonus_type == "team_sack":
			max_bonus = season_length * 6
		elif roster_contract.current_bonus_type == "KO":
			max_bonus = season_length * 2
		elif roster_contract.current_bonus_type == "5hits":
			max_bonus = int(season_length * 0.75)
		elif roster_contract.current_bonus_type == "5returns":
			max_bonus = int(season_length * 0.9) if "K" in roster_player.playable_positions else 0
		elif roster_contract.current_bonus_type == "5fow":
			max_bonus = 5 if "P" in roster_player.playable_positions else 0
		elif roster_contract.current_bonus_type == "gf":
			max_bonus = 7 * season_length
		elif roster_contract.current_bonus_type == "clean_sheet":
			max_bonus = season_length
		if max_bonus > 0:
			if roster_contract.current_bonus_prize == "salary_raise":
				contract_value += (roster_contract.current_bonus_value * max_bonus * roster_contract.original_seasons * season_length)/2 #just assume a 50% hit rate on bonuses
			elif roster_contract.current_bonus_prize == "cash_payment":
				contract_value += (roster_contract.current_bonus_value * max_bonus)/2 #just assume a 50% hit rate on bonuses
		var roster_ovr = roster_player.get_best_overall()
		position_depth.append({
			"player": roster_player,
			"contract_value": contract_value,
			"overall": roster_ovr
		})
	if position_depth.size() == 0:
		return 0
	position_depth.sort_custom(func(a, b): return a.overall > b.overall)
	var next_above = -1
	var next_below = -1
	for i in range(position_depth.size()):
		if position_depth[i].overall >= current_player_ovr:
			next_above = i
			break
	if next_above == -1:
		next_below = position_depth.size() - 1
		var overall_ratio = float(current_player_ovr) / float(position_depth[0].overall)
		return position_depth[0].contract_value * overall_ratio
	elif next_above == 0:
		next_below = 0
	else:
		next_below = next_above
		next_above = next_above - 1
	
	if next_above == -1 and next_below < position_depth.size():
		return position_depth[next_below].contract_value
	elif next_below > position_depth.size() - 1 and next_above >= 0:
		return position_depth[next_above].contract_value
	else:
		return (position_depth[next_above].contract_value + position_depth[next_below].contract_value) / 2
		return (position_depth[next_above] + position_depth[next_below])/2 #TODO: use contract value
	
func get_share_value(share):
	var revenue
	var costs
	var profit = revenue - costs
	if profit > 0:
		return profit * (float(share)/100.0)
	else:
		return 0

func offer_contract():
	var total_value = 0
	var value_weight = character.contract_focuses.get("value", 0.0) 
	var flex_weight = character.contract_focuses.get("flexibility", 0.0)
	var stability_weight = character.contract_focuses.get("stability", 0.0)
	if (value_weight + flex_weight + stability_weight) == 0:
		value_weight = 1
		if player.bio.years > 23:
			stability_weight = 2
			flex_weight = 1
		else:
			stability_weight = 0
			flex_weight = 3
		
	var weighted_value = value_weight * get_value_value() + flex_weight * get_flex_value() + stability_weight * get_stability_value()
	var match1 = get_focus_match(character.get_key_focus()) #-2.9 to 2.3
	var match2 = get_focus_match(character.get_nth_focus(1))
	var match3 = get_focus_match(character.get_nth_focus(2))
	var match4 = get_focus_match(character.get_nth_focus(3))
	var match5 = get_focus_match(character.get_nth_focus(4))
	var match6 = get_focus_match(character.get_nth_focus(5))
	var match7 = get_focus_match(character.get_nth_focus(6))
	var housing_match = get_housing_match(character.contract_focuses.house_type, current_housing) #0 to 1.45
	var promise_match = get_promise_match(current_promise)
	var sell_match = check_sell_match()
	total_value += weighted_value + match1 + match2 + match3 + match4 + match5 + match6 + match7 + housing_match + promise_match + sell_match
	#theoretical max value is 68.55
	var econ_value = 0 #even if a player doesn't care about things, adding to the contract has value
	econ_value += current_salary * 0.1
	if character.family > 0:
		econ_value += (current_food / (character.total_family)) * 0.05 #got mouths to feed
	econ_value += current_food/(400 - player.bio.pounds) #big boi bonus for food
	econ_value += (current_water / (character.family+ 1)) * 0.07
	
	var needed_value
	var sum_focuses = character.sum_focus_values()
	needed_value = player.calculate_overall() - (character.negotiation_willingness /4.5) #27.78 to 99
	var charisma_min = - 10 + CareerCoach.charisma_attributes.likeability #-10 to 10
	var charisma_max = charisma_min + CareerCoach.charisma_attributes.negotiation #equal to or up to +20
	var sign_randomness = randf_range(charisma_min, charisma_max)
	print("Offer: " + str(total_value) + " random: " + str(sign_randomness) + " econ: " + str(econ_value) + " needed: " + str(needed_value))
	if sign_randomness + total_value + econ_value >= needed_value:
		print("The player has signed!")
	else:
		if sign_randomness < character.last_contract_offer_value:
			character.negotiation_willingness -= (68.55 - total_value)
			print("offended")
		print("not good enough.")
	


func get_housing_match(wanted: String, offered: String):
	var value = 0
	var ratio = float(get_total_house_val(offered))/float(get_total_house_val(wanted))
	if ratio > 1.0:
		ratio = 1.0
	value = ratio
	value += compare_house_type_to_focus(offered)
	if wanted == offered:
		value += 0.1
	elif get_total_house_val(offered) > get_total_house_val(wanted):
		value += 0.2
	return value
	
#how well a person can sleep someplace, based on its insulation, noise, and physical space
func get_house_sleep_val(house_type: String):
	match house_type:
		"tent spot": return 1
		"encampment": return 2
		"crash pad": return 1
		"bunk house": return 1
		"cabin": return 2
		"camper": return 2
		"motel": return 2
		"bungalow": return 2
		"stationary car": return 1
		"room": return 2
		"bus": return 2
		"farmhouse": return 2
		"shanty": return 2
		"mobile car": return 1
		"compound": return 3
		"mansion": return 3
	return 0
	
#how family friendly a place is- how easy it would be to raise children there
func get_house_family_val(house_type: String):
	match house_type:
		"tent spot": return 0
		"encampment": return 0
		"crash pad": return 0
		"bunk house": return 0
		"cabin": return 1
		"camper": return 1
		"motel": return 1
		"bungalow": return 1
		"stationary car": return 1
		"room": return 1
		"bus": return 2
		"farmhouse": return 1
		"shanty": return 0
		"mobile car": return 1
		"compound": return 2
		"mansion": return 2
	return 0
	
#how connected to the community a house is, based on location, access to town, and the vibe
func get_house_community_val(house_type: String):
	match house_type:
		"tent spot": return 1
		"encampment": return 1
		"crash pad": return 2
		"bunk house": return 0
		"cabin": return 0
		"camper": return 1
		"motel": return 1
		"bungalow": return 2
		"stationary car": return 0
		"room": return 2
		"bus": return 1
		"farmhouse": return 0
		"shanty": return 0
		"mobile car": return 1
		"compound": return 0
		"mansion": return 1
	return 0
	
#combination of food growing ability (yard) and food cooking ability
func get_house_food_val(house_type: String):
	match house_type:
		"tent spot": return 0
		"encampment": return 1
		"crash pad": return 0
		"bunk house": return 1
		"cabin": return 2
		"camper": return 1
		"motel": return 2 #kitchenette, grills, some land
		"bungalow": return 2 #big yard
		"stationary car": return 2 #engine block grill, small yard
		"room": return 1
		"bus": return 1
		"farmhouse": return 3
		"shanty": return 0
		"mobile car": return 1
		"compound": return 2
		"mansion": return 3
	return 0

#how safe a house is from raiders or robbers
func get_house_security_val(house_type: String):
	match house_type:
		"tent spot": return 0
		"encampment": return 0
		"crash pad": return 1
		"bunk house": return 1
		"cabin": return 2
		"camper": return 2
		"motel": return 2
		"bungalow": return 2
		"stationary car": return 2
		"room": return 1
		"bus": return 2
		"farmhouse": return 2
		"shanty": return 1
		"mobile car": return 3
		"compound": return 4
		"mansion": return 2
	return 0

func get_total_house_val(house_type: String):
	var value = 0
	value = value + get_house_security_val(house_type)
	value = value + get_house_food_val(house_type)
	value = value + get_house_family_val(house_type)
	value = value + get_house_community_val(house_type)
	value = value + get_house_sleep_val(house_type)
	return value
	
func compare_house_type_to_focus(house_type: String) -> float:
	var housing_bonus_val = 0.0
	var top_focuses = []
	for focus in character.contract_focuses:
		top_focuses.append(focus)
	var relevant_focuses = {
		"satiety": "food",
		"opportunity": "sleep",
		"community": "community",
		"development": "sleep",
		"safety": "security",
		"education": "family",
		"farming": "food",
		"day_life": "family",
		"night_life": "community",
		"value": "security"
	}
	for focus in relevant_focuses.keys():
		if focus in top_focuses:
			var house_attr = relevant_focuses[focus]
			var house_attr_value = 0
			match house_attr:
				"food":
					house_attr_value = get_house_food_val(house_type)
				"sleep":
					house_attr_value = get_house_sleep_val(house_type)
				"community":
					house_attr_value = get_house_community_val(house_type)
				"security":
					house_attr_value = get_house_security_val(house_type)
				"family":
					house_attr_value = get_house_family_val(house_type)
			match house_attr_value:
				4:
					housing_bonus_val += 0.04
				3:
					housing_bonus_val += 0.03
				2:
					housing_bonus_val += 0.02
				1:
					housing_bonus_val += 0.01
				0:
					housing_bonus_val -= 0.02
	if housing_bonus_val > 0.25:
		housing_bonus_val = 0.25
	return housing_bonus_val

func check_sell_match():
	var match_rating = 0.0
	
	match current_sell:
		"experience":
			#gameday, travel, winning, chill - up to 4.0
			if character.contract_focuses.get("gameday", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("travel", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("win_now", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("chill", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"family":
			#loyalty, community, welfare
			if character.contract_focuses.get("loyalty", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("community", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("welfare", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"winning":
			#win now, win later, development
			if character.contract_focuses.get("win_now", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("win_later", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("development", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"future":
			#win later, development, opportunity
			if character.contract_focuses.get("win_later", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("development", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("opportunity", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"town":
			#trade, farming, day life
			if character.contract_focuses.get("trade", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("farming", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("day_life", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"kids":
			#welfare, education, day life
			if character.contract_focuses.get("welfare", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("education", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("day_life", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"fiesta":
			#party, night life, chill
			if character.contract_focuses.get("party", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("night_life", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("chill", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"adventure":
			#travel, anti-hometown (no hometown), party
			if character.contract_focuses.get("travel", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			#Add 1.0 if they don't have hometown focus, subtract 0.5 if they do
			if character.contract_focuses.get("hometown", 0) <= 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("party", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"home":
			#hometown, loyalty, safety
			if character.contract_focuses.get("hometown", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("loyalty", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("safety", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
		"quiet":
			#farming, chill, safety
			if character.contract_focuses.get("farming", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("chill", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
				
			if character.contract_focuses.get("safety", 0) > 0:
				match_rating += 1.0
			else:
				match_rating -= 0.5
	
	match_rating = match_rating * (CareerCoach.charisma_attributes.inspiration/20)
	return match_rating

func get_focus_match(focus: String):
	var match_value = 0.0
	var team_value = CareerFranchise.get_contract_focus_value(focus)
	var want_value = character.contract_focuses[focus]
	var team_letter = get_letter_value(team_value)
	var want_letter = get_letter_value(want_value)
	var letter_grades = ["F", "D-", "D", "D+", "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+", "A++"]
	var team_index = letter_grades.find(team_letter)
	var want_index = letter_grades.find(want_letter)
	if team_index == -1 or want_index == -1:
		return 0.0
	if team_index == want_index:
		match_value = 1.0
	elif team_index > want_index: #some benefit for being better than asked for
		var grade_difference = team_index - want_index
		match_value = 1.0 + (grade_difference * 0.1)
	else: #bigger penalty for not being good enough
		var grade_difference = want_index - team_index
		match_value = 1.0 - (grade_difference * 0.3)
	return match_value
	
func get_promise_match(promise: String):
	var promise_rating = 0
	var relevant_focuses = {}
	match promise:
		"none":
			return 0
		"make_captain":
			relevant_focuses = {"opportunity": 2,
			 "development": 1,
			"win_now": 1,
			"win_later": 1,
			"gameday": 1,
			"loyalty": 2
			}
			pass
		"championship":
			relevant_focuses = {"win_now": 4, "win_later": 1, "party": 1, "opportunity": 1}
			pass
		"promotion":
			relevant_focuses = {"win_now": 3, "win_later": 1, "party": 1, "opportunity": 2}
			pass
		"promo_playoff":
			relevant_focuses = {"win_now": 2, "win_later": 1, "party": 1, "opportunity": 2}
			pass
		"no_relegate":
			relevant_focuses = {"chill": 1, "win_later": 1, "party": 1, "opportunity": 1}
			pass
		"improve_front":
			if is_front_strength(): #piling it on and adding depth
				relevant_focuses = {"win_now": 2, "opportunity": -1, "development": -1}
			else: #could stand to be improved
				relevant_focuses = {"win_now": 3, "win_later": 1}
			pass
		"improve_back":
			if is_back_strength(): #piling it on and adding depth
				relevant_focuses = {"win_now": 2, "opportunity": -1, "development": -1}
			else: #could stand to be improved
				relevant_focuses = {"win_now": 3, "win_later": 1}
			pass
		"improve_training":
			relevant_focuses = {"development": 2, "win_later": 1}
			pass
		"improve_amenity":
			relevant_focuses = {"chill": 1, "family": 1, "gameday": 1, "party": 1, "travel": 1, "development": 1, "safety": 1, "medical": 0, "win_now": -1}
			pass
		"improve_party":
			relevant_focuses = {"party": 3, "chill": 1, "win_now": -2}
			pass
	for focus in relevant_focuses:
		var weight = relevant_focuses[focus]
		if character.contract_focuses.get(focus, 0) > 0:
			promise_rating += weight
	
	return promise_rating

func is_front_strength():
	#TODO: determine if the team's forwards and pitcehrs are a strength relative to the league or to the next league up
	return false
	
func is_back_strength():
	#TODO: determine if the team's guards and keepers are a strength relative to the league or to the next league up
	return false

func initial_offer():
	current_buyout = "buy100"; current_bonus_type = "goal"; current_bonus_prize = "cash_payment"
	current_bonus_value = 1; current_sell = "experience"; current_promise = "none"; current_housing = "none"
	update_buyout_value_label(); update_bonus_clause_label(); update_bonus_prize_label()
	update_bonus_value_label(); update_pitch_label(); update_promise_label(); update_housing_type_label()
