extends Node
class_name Equipment

var owned_by_team: bool = true #if not, the player who owns it takes it with them when they leave the team
var owning_player: Player
var assigned_player: Player
var item_name: String
var description: String
var img_path: String
var hue: Color
enum GearType {
	LEG, #protects the knees or shins
	ELBOW, #protects the arm
	GLOVE, #worn on either hand
	R_GLOVE, #worn on the right hand
	L_GLOVE, #worn on the left hand
	SHOE, #can impact speed, balance, agility, durability  endurance, confidence, blocking, power, shooting
	ACCESSORY #random lucky bit of gear, can be anything or impact anything
}
var gear_type: GearType
var buff: Dictionary = {} #{ "geartype": { "attributes": ["speed", "power"], "values": [10, 5] } }
enum BonusType {
	ALL, #always active
	RAIN, #player gets the bonus when it's rainy
	WIND, #gets the bonus when it's windy
	HOT, #gets the bonus when it's hot
	COLD, #gets the bonus when it's cold
	HOME, #gets the bonus at home
	AWAY, #gets the bonus on the road
	INJURED, #gets the bonus while injured
	MISMATCHED, #gets the bonus while mismatched- lose less
	MISMATCHING, #gets the bonus when the character has a mismatch- win more
	CLUTCH, #gets the bonus at the end of the game and in OT
	COMEBACK, #gets the bonus when losing
}
var buffs: Dictionary = {} #{ "bonus": { "attributes": ["speed", "power"], "values": [10, 5] } }

func get_type():
	match gear_type:
		GearType.LEG:
			return "Leg Pad"
		GearType.ELBOW:
			return "Elbow Pad"
		GearType.GLOVE:
			return "Glove"
		GearType.L_GLOVE:
			return "Left Glove"
		GearType.R_GLOVE:
			return "Right Glove"
		GearType.SHOE:
			return "Shoe"
		GearType.ACCESSORY:
			return "Accessory"
	
func get_effect():
	var string = ""
	
	for bonus_type in buffs.keys():
		var bonus_data = buffs[bonus_type]
		var attributes = bonus_data["attributes"]
		var values = bonus_data["values"]
		
		# Start with condition if bonus type is not ALL
		if bonus_type != "ALL":
			match bonus_type:
				"RAIN":
					string += "When raining, "
				"WIND":
					string += "When windy, "
				"HOT":
					string += "When hot, "
				"COLD":
					string += "When cold, "
				"HOME":
					string += "At home, "
				"AWAY":
					string += "On the road, "
				"INJURED":
					string += "While injured, "
				"MISMATCHED":
					string += "While mismatched, "
				"MISMATCHING":
					string += "When mismatching, "
				"CLUTCH":
					string += "In clutch time, "
				"COMEBACK":
					string += "When losing, "
		#else:
			#string += "Always: "
		var value_to_attributes = {}
		for i in range(attributes.size()):
			var value = values[i]
			var attribute = attributes[i]
			if not value_to_attributes.has(value):
				value_to_attributes[value] = []
			value_to_attributes[value].append(attribute)
		var effect_parts = []
		for value in value_to_attributes:
			var sign = "+" if value >= 0 else ""
			var attributes_list = ", ".join(value_to_attributes[value])
			effect_parts.append(sign + str(value) + " to " + attributes_list)
		string += "; ".join(effect_parts) + "\n"
	
	return string

func get_assigned():
	var string = ""
	if assigned_player != null:
		string += assigned_player.bio.first_name[0] + ". " + assigned_player.bio.last_name
	if !owned_by_team:
		if owning_player != null:
			string += "\n" + "Owned by: " + owning_player.bio.first_name[0] + ". " + owning_player.bio.last_name
	return string
