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

# Updated button size variables
var increment_size: Vector2 = Vector2(100, 100)  # For left section buttons
var change_size: Vector2 = Vector2(200, 100)     # For right section buttons (wider than left but smaller than action)
var action_size: Vector2 = Vector2(360, 120)     # For action buttons

func _ready():
	arrange()

func open_with_player(object: Player):
	player = object
	fill_info()
	show()

func arrange():
	arrange_left_sections()
	arrange_right_sections()
	
func arrange_left_sections():
	var left_sections = [$VBoxContainer/Bottom/ContractDetails/Seasons, $VBoxContainer/Bottom/ContractDetails/Salary, $VBoxContainer/Bottom/ContractDetails/Share, $VBoxContainer/Bottom/ContractDetails/Water, $VBoxContainer/Bottom/ContractDetails/Meals]
	
	for section in left_sections:
		var color_rect = section.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.custom_minimum_size = Vector2(400, 100)
			
			var label = color_rect.get_node_or_null("Label")
			if label:
				label.add_theme_font_size_override("font_size", 50)
				label.custom_minimum_size = Vector2(400, 100)
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
			section_label.custom_minimum_size = Vector2(400, 40)
			section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
func arrange_right_sections():
	var right_sections = [$VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/ContractType, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Housing, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Promise, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusPrize, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusValue]
	
	for section in right_sections:
		var color_rect = section.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.custom_minimum_size = Vector2(500, 100)
			
			var label = color_rect.get_node_or_null("Label")
			if label:
				label.add_theme_font_size_override("font_size", 50)
				label.custom_minimum_size = Vector2(500, 100)
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var section_label = section.get_node_or_null("Label")
		if section_label:
			section_label.add_theme_font_size_override("font_size", 40)
			section_label.custom_minimum_size = Vector2(500, 40)
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

# Add the same scale_texture_button function from training_menu
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
	pass # Replace with function body.

func _on_cancel_button_pressed() -> void:
	pass # Replace with function body.
