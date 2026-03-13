extends Node
class_name Coach

var level = 1
var xp = 0 #when it reaches 100, the character levels up

var charisma_attributes := {
	"inspiration": 10, #improves contract sells, contract promises, 
	"negotiation": 10, #improves trades, buying and selling, and contract negotiation
	"likeability": 10, #improves morale and contract negotiation
	"communication": 10, #how easily people understand your ideas
}

var training_attributes := {
	"pitchers": 10,
	"keepers": 10,
	"forwards": 10,
	"guards": 10,
	"physical": 10,
	"technical": 10,
	"mental": 10,
	"youth": 10,
	"longevity": 10
}

var perks := {
	"tinkerer": false, #buff to players when changing tactics 1 time per game
	"waterboy": false, #allows speinding water to give energy 1 time per game
	"bulk": false, #allows spending food to increase player weight and speed up strength development
	"cut": false, #allows spending water to reduce player weight and speed up speed development
}

func export_to_dict() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"charisma_attributes": charisma_attributes.duplicate(),
		"training_attributes": training_attributes.duplicate(),
		"perks": perks.duplicate()
	}

func import_from_dict(data: Dictionary):
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	charisma_attributes = data.get("charisma_attributes", charisma_attributes).duplicate()
	training_attributes = data.get("training_attributes", training_attributes).duplicate()
	perks = data.get("perks", perks).duplicate()
