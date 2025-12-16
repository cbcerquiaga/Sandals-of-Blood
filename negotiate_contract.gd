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
var housing_types = ["none", "spot", "tent", "car", "shack", "trailer", "room", "cabin", "mansion"]
var focus_types = ["value", "stability", "flexibility", "satiety", "hydration", "hometown", "housing", "gameday", "travel", "medical", "party", "chill", "win_now", "win_later", "loyalty", "opportunity", "community", "development", "safety", "education", "trade", "farming", "day_life", "night_life", "welfare"]
var bonus_types = ["gp", "win", "goal", "assist", "point", "sack", "partner_sack", "team_sack", "KO", "5hits", "5returns", "5fow", "gf", "clean_sheet"]
var bonus_prizes = ["salary_raise", "cash_payment", "feast"] #permanent raise in salary, one time cash payment, one time food payment
var bonus_values_raise = [1, 2, 3, 4, 5]
var bonus_values_cash = [1, 5, 10, 25, 100] #coin denominations
var bonus_values_feast = [1, 2, 3, 4, 5] #5 meals in one sitting would be pretty crazy
var buyout_types = ["free", "buy50", "buy100", "buy200", "nobuy"] #what it takes to cut the player: nothng, 50% of the money they're still owed, all of the money they're owed, double the money they're owed, or they can't be bought out at all
var promise_types = ["none", "make_captain", "championship", "promotion", "no_relegate", "improve_front", "improve_back", "improve_training", "improve_amenity", "improve_party"]
#no promise, make the player captain, win the league or win a special tournament, move up to the next league (top 2), not get sent down to the lower league, sign or trade for LF/P/RF, sign or trade for LG/K/RG, improve the team's training facilities or coaching staff, improve team's housing or game day, improve team's party situation
var player_family: int = 2 #how many mouths the player has to feed
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
var current_housing: String = "none"
var current_focus: String = "value"
var current_promise: String = "none"
var current_bonus_type: String = "gp"
var current_bonus_prize: String = "salary_raise"
var current_bonus_value: int = 1
var current_popup_type: String = ""

func _ready():
	debug_default_player()#TODO: Debug only
	true_max_food = max_food * (1 + player_family)
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
	current_contract_type = "franchise"
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
		player_family = family
		$VBoxContainer/Top/Knowledge/Family_player.text = str(family)
	else:
		$VBoxContainer/Top/Knowledge/Family_player.text = "?"
		player_family = 1
		
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
	pass

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
		current_food -= 1 * (1 + player_family)
	if current_food < 0:
		current_food = 0
	$VBoxContainer/Bottom/ContractDetails/Meals/Label.text = str(current_food) + " Meals / Week"

func more_meals_pressed() -> void:
	if current_food < (true_max_food):
		current_food += 1 * (1 + player_family)
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
		"value": "Maximum Value",
		"stability": "Job Stability",
		"flexibility": "Flexibility",
		"satiety": "Food Security",
		"hydration": "Water Access",
		"hometown": "Hometown Team",
		"housing": "Quality Housing",
		"gameday": "Game Day Experience",
		"travel": "Travel",
		"medical": "Medical Care",
		"party": "Post-win Ragers",
		"chill": "Chilling with Teammates",
		"win_now": "Win Now",
		"win_later": "Future Success",
		"loyalty": "Team Loyalty",
		"opportunity": "Career Opportunity",
		"community": "Community",
		"development": "Player Development",
		"safety": "Safety",
		"education": "Education",
		"trade": "Trade Market",
		"farming": "Farming Access",
		"day_life": "Day Life",
		"night_life": "Night Life",
		"welfare": "Welfare Benefits"
	}
	
	show_popup_menu(focus_types, "pitch", readable)

func _on_pitch_selected(id: int) -> void:
	if id >= 0 and id < focus_types.size():
		current_focus = focus_types[id]
		update_pitch_label()

func update_pitch_label() -> void:
	var label = $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch/Label
	match current_focus:
		"value":
			label.text = "Maximum Value"
		"stability":
			label.text = "Job Stability"
		"flexibility":
			label.text = "Flexibility"
		"satiety":
			label.text = "Food Security"
		"hydration":
			label.text = "Water Access"
		"hometown":
			label.text = "Hometown Team"
		"housing":
			label.text = "Quality Housing"
		"gameday":
			label.text = "Game Day Experience"
		"travel":
			label.text = "Travel"
		"medical":
			label.text = "Medical Care"
		"party":
			label.text = "Post-win Ragers"
		"win_now":
			label.text = "Win Now"
		"win_later":
			label.text = "Future Success"
		"loyalty":
			label.text = "Team Loyalty"
		"opportunity":
			label.text = "Playing Time"
		"community":
			label.text = "Community"
		"development":
			label.text = "Player Development"
		"safety":
			label.text = "Safety"
		"education":
			label.text = "Education"
		"trade":
			label.text = "Trade Market"
		"farming":
			label.text = "Farming Access"
		"day_life":
			label.text = "Day Life"
		"night_life":
			label.text = "Night Life"
		"welfare":
			label.text = "Welfare Benefits"

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
		"improve_amenity": "Improve Amenities",
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
		"no_relegate":
			label.text = "Avoid Relegation"
		"improve_front":
			label.text = "Improve Frontcourt"
		"improve_back":
			label.text = "Improve Backcourt"
		"improve_training":
			label.text = "Improve Training"
		"improve_amenity":
			label.text = "Improve Amenities"
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
	# Update family size for food calculations
	player_family = character.get_family_count()
	true_max_food = max_food * (1 + player_family)
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
		# Group features by player
		var players_data = {}
		
		for feature in comparables:
			var player_name = feature[4]  # Index 4 is player name
			var similarity = feature[0]    # Index 0 is similarity score
			var display_text = feature[3]  # Index 3 is display text
			
			if not players_data.has(player_name):
				players_data[player_name] = {
					"similarity": similarity,
					"features": []
				}
			
			players_data[player_name]["features"].append(display_text)
		
		# Build the display string
		string = ""
		var player_names = players_data.keys()
		for i in range(player_names.size()):
			var player_name = player_names[i]
			var player_info = players_data[player_name]
			var similarity_percent = int(player_info["similarity"])
			
			# Add player line: Name [XX%] Feature1 Feature2
			string += player_name + " [" + str(similarity_percent) + "%]"
			
			# Add up to 2 features on the same line
			for j in range(min(2, player_info["features"].size())):
				string += " " + player_info["features"][j]
			
			# Add newline if not the last player
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
	var guaranteed_total = 0
	var max_bonus = 0
	var weighted_value = guaranteed_total * 0.75 + max_bonus * 0.25
	#TODO: compare to comparables
	return 0
	
func get_flex_value():
	var buyout_value #free ok, 50 ok, 100 ok, 200 bad, none awful
	var franchise_tag #franchise tag bad
	var tradeable #tradeable ok
	var length #less length good
	return 0

func get_stability_value():
	var length #more length good
	var franchise_tag #franchise tag good
	var tradeable #tradeable bad
	var buyout_value #none is best, 200 better, 100 ok, 50 bad, free awful
	return 0

func offer_contract():
	var value_weight #weigh contract based on value
	var flex_weight #weigh contract based on flexibility
	var stability_weight #weigh contract based on stability
	var weighted_value #use weights * player focus weights for each of the key focuses
	var match1
	var match2
	var match3
	var match4
	var match5
	var match6
	var match7
	var housing_match
	var promise_match
