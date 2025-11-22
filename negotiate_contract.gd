extends Control

var player: Player

var is_tryout_contract: bool
const min_seasons: int = 1 #1 season contract
const max_seasons: int = 4 #4 season contract
const min_tryout: int = 1 #1 game tryout
const max_tryout: int = 3 #3 game tryout
const min_salary: int = 0
const max_salary: int = 100000
const min_share: int = 0
const max_share: int = 100 #full team ownership
const min_water: int = 0
const max_water: int = 250 #average modern usa water consumption
const min_food: int = 0
const max_food: int = 210 #3 meals a day for a family of 5 and double rations
var player_contract_types = ["tryout", "standard", "tradeable", "franchise"]
var staff_contract_types = ["coach", "security", "surgeon", "medic", "promoter", "grounds", "equipment", "cook", "accountant", "entourage"]
var housing_types = ["none", "spot", "tent", "car", "shack", "trailer", "room", "cabin", "mansion"]
var focus_types = ["value", "stability", "flexibility", "satiety", "hydration", "hometown", "housing", "training", "gameday", "travel", "medical", "party", "win_now", "win_later", "loyalty", "opportunity", "community", "development", "safety", "education", "trade", "farming", "day_lif", "night_life", "welfare"]
var bonus_types = ["gp", "goal", "assist", "point", "sack", "partner_sack", "team_sack", "KO", "5hits", "5returns", "5fow", "gf", "clean_sheet"]


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
var current_

func _ready():
	arrange()

func open_with_player(object: Player):
	player = object
	fill_info()
	show()

func arrange():
	arrange_portrait_section()
	arrange_top_sections()
	arrange_left_sections()
	arrange_right_sections()

func arrange_portrait_section():
	var backRect = $VBoxContainer/Top/PlayerColorRect
	var frontRect = $VBoxContainer/Top/PlayerColorRect/ColorRect
	var portrait = $VBoxContainer/Top/PlayerColorRect/ColorRect/VBoxContainer/Portrait
	var label = $VBoxContainer/Top/PlayerColorRect/ColorRect/VBoxContainer/Label
	var vbox = $VBoxContainer/Top/PlayerColorRect/ColorRect/VBoxContainer
	
	backRect.color = Color.BLACK
	backRect.custom_minimum_size = Vector2(200, 250)
	backRect.size = Vector2(200, 250)
	
	frontRect.color = Color("#585858")
	frontRect.custom_minimum_size = Vector2(180, 230)
	frontRect.size = Vector2(180, 230)
	
	vbox.custom_minimum_size = Vector2(180, 230)
	vbox.size = Vector2(180, 230)
	
	if portrait is TextureRect:
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(160, 115)
	portrait.size = Vector2(160, 115)
	
	label.add_theme_font_size_override("font_size", 20)
	label.custom_minimum_size = Vector2(160, 115)
	label.size = Vector2(160, 115)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Force position of the entire portrait section
	backRect.position = Vector2(400, backRect.position.y)

func arrange_top_sections():
	var labelRectangles = [$VBoxContainer/Top/Notes/CompsRect, $VBoxContainer/Top/Notes/LeverageRect, $VBoxContainer/Top/Notes/InterestRect]
	var notes = [$VBoxContainer/Top/Notes/Comps, $VBoxContainer/Top/Notes/Leverage, $VBoxContainer/Top/Notes/Interest]
	
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
	var right_sections = [$VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/ContractType, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Housing, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Promise, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusPrize, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusValue]
	
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

func fill_info():
	pass
	
func debug_default_player():
	pass

func _on_offer_button_pressed() -> void:
	pass

func _on_cancel_button_pressed() -> void:
	pass


func less_duration_pressed() -> void:
	pass # Replace with function body.


func more_duration_pressed() -> void:
	pass # Replace with function body.


func less_salary_pressed() -> void:
	pass # Replace with function body.


func more_salary_pressed() -> void:
	pass # Replace with function body.


func less_share_pressed() -> void:
	pass # Replace with function body.


func more_share_pressed() -> void:
	pass # Replace with function body.


func less_water_pressed() -> void:
	pass # Replace with function body.


func more_water_pressed() -> void:
	pass # Replace with function body.


func less_meals_pressed() -> void:
	pass # Replace with function body.


func more_meals_pressed() -> void:
	pass # Replace with function body.


func change_contract_type() -> void:
	pass # Replace with function body.


func change_housing_type() -> void:
	pass # Replace with function body.


func change_pitch_offered() -> void:
	pass # Replace with function body.


func change_promise_offered() -> void:
	pass # Replace with function body.


func change_bonus_clause() -> void:
	pass # Replace with function body.


func change_bonus_prize() -> void:
	pass # Replace with function body.


func change_bonus_value() -> void:
	pass # Replace with function body.
