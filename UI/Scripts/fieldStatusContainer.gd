extends Container
class_name FieldStatusContainer

var portrait_holder: Sprite2D#frame which contains the portrait
var portrait: Sprite2D
var name_tag: Sprite2D#background for nametag text
var boostContainer: Sprite2D #shows max boost
var balanceContainer: Sprite2D#shows max balance
var grooveContainer: Sprite2D #shows max groove
var balanceBar: Sprite2D #shows current stability
var boostBar: Sprite2D #shows current boost
var grooveBar: Sprite2D #shows current groove
var statusSymbol: Sprite2D #if character has a status, shows it
var nameLabel: Label #shows player's name
var player: Player

var base_texture_size: Vector2 = Vector2(0.353, 0.311)

func _ready() -> void:
	portrait_holder = $PortraitHolder1
	portrait = $PortraitHolder1/Portrait
	name_tag = $NameTag
	boostContainer = $BoostContainer
	boostBar = $BoostBar
	balanceContainer = $BalanceContainer
	balanceBar = $BalanceBar
	grooveContainer = $GrooveContainer
	grooveBar = $GrooveBar
	nameLabel = $NameLabel
	statusSymbol = $StatusSymbol
	
func _process(delta: float) -> void:
	if !player:
		print("no player in UI container")
		return
	update_boost_bars()
	update_balance_bars()
	update_groove_bars()
	make_name_string()
	
func assign_player(character: Player):
	if character.position_type == "forward" or character.position_type == "guard":
		grooveBar.visible = false
		grooveContainer.visible = false
	player = character
	make_name_string()
	get_player_portrait()
	
func make_name_string():
	var str = ""
	if player.plays_left_side:
		if player.position_type == "forward":
			str = "LF"
		else:
			str = "LG"
	else:
		match player.position_type:
			"forward":
				str = "RF"
			"guard":
				str = "RG"
			"keeper":
				str = "K"
			"pitcher":
				str = "P"
	str += " "
	str += player.bio.last_name
	nameLabel.text = str
	nameLabel.scale = Vector2(2.5, 2)
	
func get_player_portrait():
	if !player or !player.portrait:
		print("error loading player portrait for ", player.bio.first_name, " ", player.bio.last_name)
		return
	portrait.texture = load(player.portrait)
	portrait.scale = Vector2(0.7, 0.7)
	portrait.position = Vector2(0, 0)
	
func update_boost_bars():
	var boost_percent = player.status.boost / 99 * 100 #max is 99 because of attributes
	var boost_bar_position = boost_percent * 3 - 1 #100 is 300, 0 is -1
	var boost_bar_scale = boost_percent * (0.0035657) + 0.001
	var boost_container_scale = player.status.max_boost / 99 * 100 * (0.0035657) + 0.001
	var boost_container_position = player.status.max_boost / 99 * 300 - 1
	boostBar.scale = Vector2(boost_bar_scale, base_texture_size.y)
	boostBar.position = Vector2(boost_bar_position, boostBar.position.y)
	boostContainer.scale = Vector2(boost_container_scale, base_texture_size.y)
	boostContainer.position = Vector2(boost_container_position, boostContainer.position.y)
	
func update_balance_bars():
	var stability_percent = player.status.stability / 99.0 * 100.0  # max is 99
	var balance_percent = player.attributes.balance / 99.0 * 100.0  # max is 99
	var balance_bar_position = stability_percent * 3 - 1  # 100 is 300, 0 is -1
	var balance_bar_scale = stability_percent * 0.0035657 + 0.001
	var balance_container_scale = balance_percent * 0.0035657 + 0.001
	var balance_container_position = balance_percent * 3 - 1
	balanceBar.scale = Vector2(balance_bar_scale, base_texture_size.y)
	balanceBar.position = Vector2(balance_bar_position, balanceBar.position.y)
	balanceContainer.scale = Vector2(balance_container_scale, base_texture_size.y)
	balanceContainer.position = Vector2(balance_container_position, balanceContainer.position.y)
	#print("stability: ", player.status.stability, " balance: ", player.attributes.balance, " position: " + str(balance_container_position))
	
func update_groove_bars():
	var groove_percent = player.status.groove / 99.0 * 100.0  # max is 99
	var confidence_percent = player.attributes.confidence / 99.0 * 100.0  # max is 99
	var groove_bar_position = groove_percent * 3 - 1  # 100 is 300, 0 is -1
	var groove_bar_scale = groove_percent * 0.0035657 + 0.001
	var groove_container_scale = confidence_percent * 0.0035657 + 0.001
	var groove_container_position = confidence_percent * 3 - 1
	grooveBar.scale = Vector2(groove_bar_scale, base_texture_size.y)
	grooveBar.position = Vector2(groove_bar_position, grooveBar.position.y)
	grooveContainer.scale = Vector2(groove_container_scale, base_texture_size.y)
	grooveContainer.position = Vector2(groove_container_position, grooveContainer.position.y)
