extends Node
class_name Equipment

var item_name: String
var description: String
var img_path: String
var hue: Color
var isLeft: bool = false #only applies for gloves, must match character handedness
enum GearType {
	HELMET, #protects the head
	GLOVE, #worn on just one hand
	SHOE, #can impact speed, balance, agility, durability  endurance, confidence, blocking, power, shooting
	KEEPING_PAD, #assigned to team instead of player- active keeper gets the pads
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
