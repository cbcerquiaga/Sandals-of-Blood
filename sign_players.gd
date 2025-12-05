extends Control

@onready var filter_position_button: TextureButton = $main/Filter/FilterPosition
@onready var filter_style_button: TextureButton = $main/Filter/FilterStyle
@onready var filter_traits_button: TextureButton = $main/Filter/FilterTraits
@onready var sort_button: TextureButton = $main/Filter/Sort

@onready var scrolling_area: VBoxContainer = $main/ScrollContainer/VBoxContainer
@onready var back_button: TextureButton = $main/Actions/Back

@onready var popup: PopupMenu = $PopupMenu

func player_selected(player: Character):
	print("Player selected: " + player.bio.last_name)
	#look at the player's current contract
	#TODO: if the contract is tradeable- add "Trade" item to popup
	#TODO: if the player is not under contract or signed to a staff contract, add "Sign (Free)" item to popup
	#TODO: if the player is signed on a standard contract, add "Sign (1 Token)" item to popup
	#TODO: if the player is signed on a franchise contract, add "Sign (2 Tokens)" item to popup
	#TODO: add "Comparables" item to popup
	#TODO: add "Career" item to popup

func comparables_button_pressed(player: Character):
	print("Finding comparable contracts")
	#find players who are similar and under similar contract
	#TODO: look for players who are the same player type
	var num_positions = player.playable_positions.size()
	if player.bio.age < 20:
		print("youngblood")
		#TODO: look for players who are also under 20
	elif player.bio.age >35:
		print("oldhead")
		#TODO: look for players who are also over 35
	else:
		print("prime age")
		#TODO: look for players who are within the same age by 2 years if possible
	#TODO: of all the available players, score their similarity based on overall rating and how many positions they play (A plays 5 and B plays 6 is 83% similar, A is 75 and B is 77 is 97% similar, avg is 90% similar) 
	#TODO: pick out the 3 most similar players
	var player1
	var player2
	var player3
	pick_6_contract_features(player1, player2, player3)

func pick_6_contract_features(player1: Character, player2: Character, player3: Character):
	print("here are your similar players:")
	#TODO: pick out 6 features from the players' contracts. 
	#TODO: make sure that there are not more than 2 repeated features
	
#used when sign (free), sign (1 token) or sign (2 tokens) is pressed
func sign_player_pressed(num_tokens:int = 0):
	#TODO: pass in num_tokens, comparable players, and 6 contract features
	get_tree().change_scene_to_file("res://negotiate_contract.tscn")


func _on_filter_position_pressed() -> void:
	$PositionsMenu.show()
	pass # Replace with function body.



func _on_filter_style_pressed() -> void:
	pass # Replace with function body.


func _on_filter_traits_pressed(looking_for_players:bool = true) -> void:
	$TraitsMenu.show()
	if looking_for_players:
		$TraitsMenu/StaffRole.hide()
		$TraitsMenu/ContractType.show()
	else:
		$TraitsMenu/StaffRole.show()
		$TraitsMenu/ContractType.hide()
	pass # Replace with function body.



func _on_sort_pressed() -> void:
	pass # Replace with function body.


func _on_reset_pressed() -> void:
	#TODO: reset all filters and sorts to default
	pass # Replace with function body.
	
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://manager_hub_menu.tscn")
	pass # Replace with function body.


#region player_filtering
func _on_filter_changed():
	#TODO: update the player list
	pass

func _on_free_agents_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include free agents in list
	#TODO: if false, don't include free agents
	pass
	
func _on_standard_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include standard contracts in list
	#TODO: if false, don't include standard contracts
	pass

func _on_tradeable_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include tradeable contracts in list
	#TODO: if false, don't include tradeable contracts
	pass


func _on_franchise_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include franchise contracts in list
	#TODO: if false, don't include franchise contracts
	pass


func _on_staff_toggled(toggled_on: bool) -> void: #default: false
	#TODO: if true, include staff contracts in list
	#TODO: if false, don't include staff contracts
	pass

func _on_strong_toggled(toggled_on: bool) -> void: #default: false
	var strength_attributes = ["power", "balance"]
	var avg_strength_f = 75 #TODO: pull this from the league data
	var avg_strength_g = 85
	var avg_strength_p = 85
	var avg_strength_k = 70
	#TODO: filter out players who have lower average strength attributes than the avg at a position


func _on_fast_toggled(toggled_on: bool) -> void:
	var speed_attributes = ["speedRating", "agility", "endurance", "reactions"]
	var avg_speed_f = 85 #TODO: pull this from the league data
	var avg_speed_g = 75
	var avg_speed_p = 75
	var avg_speed_k = 90
	#TODO: filter out players who have lower average speed attributes than the avg at a position
	
func _on_technical_toggled(toggled_on: bool) -> void:
	var tech_attributes_f = ["shooting", "accuracy"]
	var tech_attributes_g_k = ["shooting", "accuracy", "blocking"] #both guards and keepers
	var tech_attributes_p = ["throwing", "accuracy", "faceoffs", "focus"]
	var avg_tech_f = 75 #TODO: pull this from the league data
	var avg_tech_g = 75
	var avg_tech_p = 75
	var avg_tech_k = 75
	#TODO: filter out players who have a lower average technical attribute than the avg at a position

func _on_tough_toggled(toggled_on: bool) -> void:
	var tough_attributes = ["shooting", "balance", "endurance", "toughness"]
	var avg_tough_f = 75 #TODO: pull this from the league data
	var avg_tough_g = 85
	var avg_tough_p = 80
	var avg_tough_k = 60
	#TODO: filter out players who have a lower average toughness attributes than the avg at a position

func _on_smart_pressed() -> void:
	var smart_attributes_p = ["confidence", "discipline", "reactions"]
	var smart_attributes_f_g_k = ["positioning", "reactions", "discipline"] #guards, keepers, and forwards
	var avg_brain_f = 65 #TODO: pull this from the league data
	var avg_brain_g = 65
	var avg_brain_p = 80
	var avg_brain_k = 80
	#TODO: filter out players who have a lower average mental attributes than the avg at a position

func _on_min_age_selected(index: int) -> void: #default: 0
	var age #TODO: get from index
	#TODO: filter out players under the selected minumum age


func _on_max_age_selected(index: int) -> void: #default: 120
	var age #TODO: get from index
	#TODO: filter out players over the selected maximum age
	
func _on_lefty_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if false, filter out left handed players
	pass # Replace with function body.


func _on_righty_toggled(toggled_on: bool) -> void:#default: true
	#TODO: if false, filter out right handed players
	pass # Replace with function body.


func _on_full_scout_only_toggled(toggled_on: bool) -> void: #default: false
	pass # Replace with function body.
	
func _on_check_box_attribute1_toggled(toggled_on: bool) -> void: #default: false
	#TODO: filter based on $TraitsMenu/GenTraits/Attribute1/Attribute for values between $TraitsMenu/GenTraits/Attribute1/Min and $TraitsMenu/GenTraits/Attribute1/Max inclusive
	pass # Replace with function body.


func _on_attribute_1_selected(index: int) -> void:
	#TODO: update filtering
	pass # Replace with function body.

func _on_min_attribute_1_selected(index: int) -> void:
	#TODO: update filtering
	pass # Replace with function body.

func _on_max_attribute_1_selected(index: int) -> void:
	pass # Replace with function body.

#TODO: attribute 2 just like attribute 1
func _on_check_box_attribute2_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_attribute_2_selected(index: int) -> void:
	pass # Replace with function body.

func _on_min_attribute_2_selected(index: int) -> void:
	pass # Replace with function body.
	
func _on_max_attribute_2_selected(index: int) -> void:
	pass # Replace with function body.

#TODO: just like 1 and 2
func _on_check_box_attribute3_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_attribute_3_selected(index: int) -> void:
	pass # Replace with function body.

func _on_min_attribute_3_selected(index: int) -> void:
	pass # Replace with function body.

func _on_max_attribute_3_selected(index: int) -> void:
	pass # Replace with function body.

func _on_plays_lf_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the left forward position
	pass # Replace with function body.


func _on_plays_p_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the pitcher position
	pass # Replace with function body.


func _on_plays_rf_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the right forward position
	pass # Replace with function body.


func _on_plays_lg_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the left guard position
	pass # Replace with function body.
	
func _on_plays_k_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the keeper position
	pass # Replace with function body.

func _on_plays_rg_toggled(toggled_on: bool) -> void: #default: true
	#TODO: include players who can play the right guard position
	pass # Replace with function body.

func _on_min_positions_selected(index: int) -> void: #default: 1
	var num_positions = index + 1
	#TODO: filter out players who play fewer than the selected number
	pass # Replace with function body.


func _on_max_positions_selected(index: int) -> void: #default: 6
	var num_positions = index + 1
	#TODO: filter out players who play more than the selected number
	pass # Replace with function body.

#endregion

#region staff_filtering

func _on_coach_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.
	
func _on_scout_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.


func _on_grounds_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.


func _on_kit_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.
	
func _on_doctor_pressed() -> void: #default: true
	pass # Replace with function body.

func _on_trainer_pressed() -> void: #default: true
	pass # Replace with function body.
	
func _on_chef_pressed() -> void: #default: true
	pass # Replace with function body.
	
func _on_entourage_pressed() -> void: #default: true
	pass # Replace with function body.


func _on_security_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.


func _on_promo_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.


func _on_money_toggled(toggled_on: bool) -> void: #default: true
	pass # Replace with function body.
	

#endregion




func _on_anti_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the anti-keeper style
	pass # Replace with function body.


func _on_scorer_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the goal scorer style
	pass # Replace with function body.


func _on_skull_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the skullcracker style
	pass
	

func _on_support_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the support forward style
	pass # Replace with function body.


func _on_defender_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the defender style
	pass # Replace with function body.



func _on_ball_hound_toggled(toggled_on: bool) -> void:#default: true
	#TODO: if true, include players with the ball hound style
	pass # Replace with function body.


func _on_bully_toggled(toggled_on: bool) -> void:#default: true
	#TODO: if true, include players with the bully style
	pass # Replace with function body.


func _on_ace_toggled(toggled_on: bool) -> void:#default: true
	#TODO: if true, include players with the ace style
	pass # Replace with function body.


func _on_hatchet_toggled(toggled_on: bool) -> void:#default: true
	#TODO: if true, include players with the hatchet man style
	pass # Replace with function body.


func _on_hog_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the track hog style
	pass # Replace with function body.


func _on_maestro_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the maestro style
	pass # Replace with function body.


func _on_machine_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the machine style
	pass # Replace with function body.


func _on_spin_dr_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the spin doctor style
	pass # Replace with function body.

func _on_workhorse_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the workhorse style
	pass # Replace with function body.


func _on_prospect_toggled(toggled_on: bool) -> void: #default: true
	#TODO: if true, include players with the prospect goalkeeper style
	pass # Replace with function body.
