extends Node
class_name Equipment

var item_name: String
var description: String
var img_path: String
var hue: Color
var canLeft: bool = true #usually true, but if a glove is only for one hand, one of these will be false
var canRight: bool = true
enum GearType {
	LEG, #protects the knees or shins
	ELBOW, #protects the arm
	GLOVE, #worn on just one hand
	SHOE, #can impact speed, balance, agility, durability  endurance, confidence, blocking, power, shooting
	ACCESSORY #random lucky bit of gear, can be anything or impact anything
}
var gear_type: GearType
var buff: Dictionary = {} #{ "geartype": { "attributes": ["speed", "power"], "values": [10, 5] } }
enum BonusType {
	RAIN, #player gets the bonus when it's rainy
	WIND, #gets the bonus when it's windy
	HOT, #gets the bonus when it's hot
	COLD, #gets the bonus when it's cold
	HOME, #gets the bonus at home
	AWAY, #gets the bonus on the road
	INJURED, #gets the bonus while injured
}
var bonus_type: BonusType
var bonus_buff: Dictionary = {}

func get_title():
	var string = ""
	if canLeft and !canRight:
		string += "Left Handed "
	elif canRight and !canLeft:
		string += "Right Handed "
	string += item_name
	return string
