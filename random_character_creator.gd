extends Node
class_name randomCharacterGenerator

var characters:= []
var min_overall: int = 30
var max_overall: int = 90
var min_potential: int = 30
var max_potential: int = 99
var left_hand_frequency: float = 0.25
var male_frequency_players: float = 0.93 #percentage of player gens who are going to be male
var male_frequency_general: float = 0.44 #percentage of non-player characters who are going to be male
var intersex_frequency: float = 0.017 #percentage of players and non-player characters who will be intersex
var min_age: int = 8 #minimum age of generated characters
var max_age: int = 50 #maximum age of generated characters
var min_player_age = 13
var max_player_age = 44


var unemployment_rate = 0.58
var subsistence_farmer_rate = 0.3
var gang_rate = 0.25
var gangs = ["The Posse", "Banana Republicans", "Metalheads", "The Family", "Holy Rollers"]

var rando_age_weights := {
	"0-4": 14,
	"5-9": 13,
	"10-14": 11,
	"15-19": 9,
	"20-24": 10,
	"25-39": 8,
	"30-34": 7,
	"35-39": 6,
	"40-44": 5,
	"45-49": 4,
	"50-54": 3.75,
	"55-59": 2,
	"60-64": 2.1,
	"65-69": 1.5,
	"70-74": 1,
	"75-110": 0.5
}

var non_player_type_frequency:={
	"coach": 10, #good at coaching in general
	"strength_coach": 12, #good at physical training
	"skills_coach": 12, #good at technical training
	"offense_coordinator": 8, #good at tactical training
	"sport_sensei": 4, #good at tactical and scouting
	"scout": 10, #good at scouting
	"surgeon": 0.2, #good trauma and ortho
	"rehabilitator": 0.2, #good ortho and rehab
	"doctor": 2, #good medicine
	"trainer": 5, #good stretching, ok first aid and rehab
	"paramedic": 3, #good first aid, ok stretching and rehab
	"military_paramedic": 1, #good first aid and anti-banditry
	"carpenter": 1, #good carpentry, bad masonry and painting
	"mason": 1, #good masonry, bad carpentry and painting
	"painter": 2, #good painting, bad carpentry and masonry
	"handyman": 4, #ok at caprentry, masonry, and painting
	"master_craftsman": 0.2, #good at carpentry, masonry, and painting
	"salesman": 20, #good at attraction
	"people_pleaser": 10, #good at sponsorship and networking
	"tailor": 2, #good at sewing
	"porter": 15, #good at carrying
	"logistician": 4, #good at acquisitions
	"kitman":1, #ok at tailoring, carrying, and acquisitions
	"traveling_merchant": 4, #good at carrying and attraction
	"big_family_cook": 8, #good at line cooking and home cooking
	"haute_chef": 1, #good at fine cooking and line cooking
	"grill_master": 5, #good at home cooking and fine cooking
	"spreadsheet_wizard": 5, #good at auditing and budgeting
	"business_sleuth": 5, #good at auditing and sleuthing
	"groupie": 10, #good at raging, ok at intimacy, bad at chilling
	"prostitute": 25, #good at intimacy, ok at raging and chilling
	"homie": 10, #good at chilling, ok at raging, 0 intimacy
	"party_planner": 5, #good at raging and chilling, bad at intimacy
	"bodyguard": 10, #good at escorting and anti-banditry
	"escort": 5, #good at escorting and intimacy
	"usher": 8, #good at de-escalation
	"minder": 4, #good at de-escalation and escorting
	"contract_lawyer": 0.5, #good at bidding and sponsorship
	"gun_for_hire": 25, #good at anti-banditry and raging
	"friendly_face": 1, #good at de-escalation and chilling, very high charisma
	"gym_bro": 1, #good at physical training, stretching, and carrying
}

var key_focus_frequency := {
	"value": 4.0,
	"flexibility": 1.0,
	"stability": 3.0
}

var other_contract_focus_frequency:= {
	#primary focuses
	"value": 1.0,
	"stability": 1.0,
	"flexibility": 1.0, 
	"satiety": 1.0, #goes way up for big boys
	"hydration": 1.0, #goes way up for players with more ambition
	"hometown": 2.0,
	"housing": 2.0, #goes up for playuers with higher overalls and players with families
	"gameday": 1.0,
	"travel": 1.0,
	"medical": 0.5, #goes way up if player is higher in age
	"party": 2.0,
	"chill": 1.0, 
	"win_now": 2.0, 
	"win_later": 1.0, #goes way down if player is higher in age
	"loyalty": 2.0,
	"opportunity": 2.0,
	"community": 1.0, #goes up for players with families and players with 
	"development": 1.0, 
	"safety": 0.5, #goes up for players with families and players from rural areas, higher for war day job
	"education": 0.5, #goes up for younger players and players with families
	"trade": 1.0, #goes way up for players with day job  in industrial, trade,transport, or finance
	"farming": 1.0, #goes way up for players with day job in farming
	"day_life": 1.0, #goes up for players from urban areas and players with families, slightly higher for younger players
	"night_life": 1.0, #higher for hospitality day job, slightly higher for older players
	"welfare": 1.0 #goes up for players with families and older players, higher for public day job
}

var preferred_room_type_frequency:={
	"tent spot":  0.5, #goes up for players with no day job
	"encampment":  1,
	"crash pad":  1.5,
	"bunk house":  2,
	"cabin":  2.5, #higher or players from rural places
	"camper":  2.5,
	"motel":  2.5,#higher for players from urban places
	"bungalow":  2.5,
	"stationary car":  2,
	"room":  3,
	"bus":  3,
	"farmhouse":  4,
	"shanty":  1,
	"mobile car":  4,
	"compound":  0.5,#obviously the nicest houses are the most desirable, but only let players with high overalls want these
	"mansion":  0.5,
}

# Height distributions (in inches) - Post-apocalyptic setting, all heights in inches
var height_distribution = {
	"male": {"min": 59, "max": 84, "avg": 68, "std_dev": 3.5},  # 4'11" to 7'0"
	"female": {"min": 53, "max": 81, "avg": 65, "std_dev": 3.5}  # 4'5" to 6'9"
}

# Post-apocalypse weight categories (BMI ranges converted to lbs for average height)
var weight_categories = {
	"stunted": { 
		"weight_range": {"min": 90, "max": 120},
		"frequency": 15,
		"bmi_range": {"min": 15.0, "max": 17.5}
	},
	"starving": {
		"weight_range": {"min": 110, "max": 140},
		"frequency": 20,
		"bmi_range": {"min": 17.5, "max": 19.0}
	},
	"scrawny": {
		"weight_range": {"min": 130, "max": 160},
		"frequency": 25,
		"bmi_range": {"min": 19.0, "max": 20.5}
	},
	"lean": {
		"weight_range": {"min": 150, "max": 180},
		"frequency": 20,
		"bmi_range": {"min": 20.5, "max": 22.0}
	},
	"old_world": {
		"weight_range": {"min": 160, "max": 210},
		"frequency": 10,
		"bmi_range": {"min": 22.0, "max": 25.0}
	},
	"built": {
		"weight_range": {"min": 180, "max": 230},
		"frequency": 4,
		"bmi_range": {"min": 25.0, "max": 27.5}
	},
	"heavy": {
		"weight_range": {"min": 200, "max": 260},
		"frequency": 3,
		"bmi_range": {"min": 27.5, "max": 30.0}
	},
	"stocky": {
		"weight_range": {"min": 230, "max": 290},
		"frequency": 2,
		"bmi_range": {"min": 30.0, "max": 33.0}
	},
	"bulky": {
		"weight_range": {"min": 260, "max": 310},
		"frequency": 0.8,
		"bmi_range": {"min": 33.0, "max": 36.0}
	},
	"huge": {
		"weight_range": {"min": 290, "max": 330},
		"frequency": 0.2,
		"bmi_range": {"min": 36.0, "max": 40.0}
	},
	"colossal": {
		"weight_range": {"min": 320, "max": 350},
		"frequency": 0.05,
		"bmi_range": {"min": 40.0, "max": 45.0}
	}
}

#players are more likely to be bigger, healthier people than the average apocalypto
var player_weight_frequency_adjustment = {
	"stunted": 0.3,
	"starving": 0.5,
	"scrawny": 0.8,
	"lean": 1.2,
	"old_world": 1.5,
	"built": 2.0,
	"heavy": 1.8,
	"stocky": 1.5,
	"bulky": 1.0,
	"huge": 0.5,
	"colossal": 0.1 
}

var player_overall_rates:={
	20: 5.0, #possibly the least athletic person you have ever seen
	21: 5.0,
	22: 5.0,
	23: 5.0,
	24: 5.0,
	25: 5.0, #not a player
	26: 5.0,
	27: 5.0,
	28: 5.0,
	29: 5.0,
	30: 5.0,
	31: 5.0,
	32: 5.0,
	33: 5.0,
	34: 5.0,
	35: 5.0,
	36: 4.9,
	37: 4.8,
	38: 4.8, #could get really hurt even stepping on the field
	39: 4.7,
	40: 4.6,
	41: 4.6,
	42: 4.5,
	43: 4.5,
	44: 4.4,
	45: 7.0, #potentially a B player
	46: 4.4,
	47: 4.3,
	48: 4.3,
	49: 4.2,
	50: 4.2,
	51: 4.1,
	52: 6.8, #low end of average B player
	53: 4.1,
	54: 4.0,
	55: 4.0,
	56: 6.6, #average bench player in B
	57: 3.9,
	58: 3.9,
	59: 3.8,
	60: 6.4, #low end bench player in A
	61: 3.8,
	62: 3.7,
	63: 3.7,
	64: 6.2, #average bench player in A
	65: 3.6,
	66: 5.0, #average B starter
	67: 3.6,
	68: 6.0, #low end bench player in AA
	69: 3.6,
	70: 3.5,
	71: 3.5,
	72: 5.8, #average bench player in AA
	73: 3.4,
	74: 5.6, #average starter in A
	75: 3.4,
	76: 3.3,
	77: 5.4, #low end bench player in AAA
	78: 3.3,
	79: 3.2,
	80: 5.2, #average bench player in AAA
	81: 3.1,
	82: 5.0, #average starter in AA
	83: 3.1,
	84: 3.0,
	85: 3.0,
	86: 2.9,
	87: 2.9,
	88: 2.8,
	89: 2.8,
	90: 4.8, #average starter in AAA
	91: 2.7,
	92: 2.7,
	93: 2.6,
	94: 2.6,
	95: 2.5,
	96: 2.4,
	97: 2.3,
	98: 2.2,
	99: 0.1
}

var name_frequency_first:= {
	"common": 40,
	"apocalypse": 10,
	"afro": 15,
	"spanish": 12,
	"french": 3,
	"italian": 2,
	"slavic": 2,
	"arab": 1,
	"nordic": 2,
	"indian": 1,
	"japanese": 0.5,
	"chinese": 2,
	"korean": 0.5,
	"wasp": 5,
	"africa": 5,
	"pacific": 1,
}

var name_frequency_last:= {
	"common": 36.3,
	"italian": 9,
	"apocalypse": 11.7,
	"spanish": 15,
	"french": 7,
	"slavic": 3,
	"nordic": 3,
	"indian": 1,
	"arab": 1,
	"japanese": 0.5,
	"chinese": 2,
	"korean": 0.5,
	"wasp": 5,
	"africa": 4,
	"pacific": 1,
}

var mix_fix_chance:= {
	"common": 0.1,
	"apocalypse": 0.2,
	"afro": 0, #can't because there isn't a last name equivalent
	"spanish": 0.4,
	"french": 0.2,
	"italian": 0.1,
	"slavic": 0.7,
	"nordic": 0.6,
	"indian": 0.8,
	"japanese": 0.8,
	"chinese": 0.5,
	"korean": 0.5,
	"wasp": 0.6,
	"africa": 0.8,
	"pacific": 0.2,
}

var position_frequency:= {
	"P": 0.245,
	"K": 0.202,
	"LG": 0.138,
	"RG": 0.138,
	"LF": 0.138,
	"RF": 0.138
}

var multi_position_frequency:= {
	1: 0.5,
	2: 0.25,
	3: 0.125,
	4: 0.065,
	5: 0.04,
	6: 0.02
}

var pitcher_styles = {
	"Ace": 35,
	"Workhorse": 5,
	"Hatchet Man": 30,
	"Track Hog": 30
}

var keeper_styles = {
	"Acrobatic": 20,
	"Crouching": 30,
	"Kneeling": 30,
	"Standing": 20
}

var forward_styles = {
	"Goal Scorer": 30,
	"Anti-Keeper": 30,
	"Support Forward": 20,
	"Skull Cracker": 20
}

var guard_styles = {
	"Ball Hound": 30,
	"Defender": 35,
	"Bully": 35
}

const HEIGHT_MODIFIERS = {
	"agility": -0.8,
	"balance": -0.6,
	"throwing": 0.7,
	"faceoffs": 0.5,
	"blocking": 0.3
}

# Weight category attribute modifiers
const WEIGHT_CATEGORY_MODIFIERS = {
	"stunted": {
		"endurance": 15,
		"speedRating": 20,
		"agility": 10,
		"power": -25,
		"toughness": -20,
		"durability": -15,
		"balance": -5
	},
	"starving": {
		"endurance": 12,
		"speedRating": 15,
		"agility": 8,
		"power": -20,
		"toughness": -15,
		"durability": -12,
		"balance": -4
	},
	"scrawny": {
		"endurance": 8,
		"speedRating": 10,
		"agility": 6,
		"power": -15,
		"toughness": -10,
		"durability": -8,
		"balance": -3
	},
	"lean": {
		"endurance": 5,
		"speedRating": 8,
		"agility": 4,
		"power": -8,
		"toughness": -5,
		"durability": -4,
		"balance": -2
	},
	"old_world": {
		"endurance": 0,
		"speedRating": 0,
		"agility": 0,
		"power": 0,
		"toughness": 0,
		"durability": 0,
		"balance": 0
	},
	"built": {
		"endurance": -3,
		"speedRating": -2,
		"agility": -1,
		"power": 10,
		"toughness": 8,
		"durability": 6,
		"balance": 3
	},
	"heavy": {
		"endurance": -6,
		"speedRating": -5,
		"agility": -3,
		"power": 15,
		"toughness": 12,
		"durability": 10,
		"balance": 5
	},
	"stocky": {
		"endurance": -10,
		"speedRating": -8,
		"agility": -6,
		"power": 20,
		"toughness": 18,
		"durability": 15,
		"balance": 8
	},
	"bulky": {
		"endurance": -15,
		"speedRating": -12,
		"agility": -10,
		"power": 25,
		"toughness": 22,
		"durability": 20,
		"balance": 12
	},
	"huge": {
		"endurance": -20,
		"speedRating": -18,
		"agility": -15,
		"power": 30,
		"toughness": 28,
		"durability": 25,
		"balance": 15
	},
	"colossal": {
		"endurance": -25,
		"speedRating": -25,
		"agility": -20,
		"power": 35,
		"toughness": 35,
		"durability": 30,
		"balance": 20
	}
}
#region jobs
# Job-related data based on City.gd
var job_rates = {
	"farm": 30,
	"trade": 25,
	"transport": 15,
	"war": 5,
	"hospitality": 10,
	"finance": 5,
	"medical": 3,
	"industrial": 4,
	"public": 3
}

var class_distribution = {
	"exploited": 25,
	"poverty": 30,
	"lower_working": 25,
	"upper_working": 10,
	"middle": 5,
	"white_collar": 3,
	"investor": 2
}

var job_titles = {
	"farm": {
		"exploited": "sharecropper",
		"poverty": "subsistence",
		"lower_working": "farmhand",
		"upper_working": "co-op farmer",
		"middle": "family farmer",
		"white_collar": "veterinarian",
		"investor": "haciendero"
	},
	"trade": {
		"exploited": "sweatshopper",
		"poverty": "home crafter",
		"lower_working": "wage crafter",
		"upper_working": "co-op shopkeeper",
		"middle": "shopkeeper",
		"white_collar": "promoter",
		"investor": "entrepreneur"
	},
	"transport": {
		"exploited": "rickshaw runner",
		"poverty": "rickshaw biker",
		"lower_working": "longshoreman",
		"upper_working": "horse teamster",
		"middle": "truck teamster",
		"white_collar": "mechanic",
		"investor": "warehouse owner"
	},
	"war": {
		"exploited": "conscript",
		"poverty": "garrison trooper",
		"lower_working": "road trooper",
		"upper_working": "driver",
		"middle": "lower officer",
		"white_collar": "siege engineer",
		"investor": "warlord"
	},
	"hospitality": {
		"exploited": "sex slave",
		"poverty": "prostitute",
		"lower_working": "cook for hire",
		"upper_working": "escort",
		"middle": "cart cook",
		"white_collar": "musician",
		"investor": "pimp"
	},
	"finance": {
		"exploited": "beggar",
		"poverty": "hawker",
		"lower_working": "repo man",
		"upper_working": "hitman",
		"middle": "loan shark",
		"white_collar": "accountant",
		"investor": "mafioso"
	},
	"medical": {
		"exploited": "blood stock",
		"poverty": "herb grower",
		"lower_working": "paramedic",
		"upper_working": "nurse",
		"middle": "medical trainer",
		"white_collar": "surgeon",
		"investor": "insurer"
	},
	"industrial": {
		"exploited": "chain gang",
		"poverty": "scrapper",
		"lower_working": "apprentice",
		"upper_working": "journeyman",
		"middle": "master",
		"white_collar": "artisan",
		"investor": "baron"
	},
	"public": {
		"exploited": "eunuch",
		"poverty": "janitor",
		"lower_working": "courier",
		"upper_working": "firefighter",
		"middle": "teacher",
		"white_collar": "professor",
		"investor": "aristocrat"
	}
}

var job_pay_ranges = {
	"exploited": {"min": 0, "max": 15},
	"poverty": {"min": 10, "max": 25},
	"lower_working": {"min": 20, "max": 35},
	"upper_working": {"min": 30, "max": 60},
	"middle": {"min": 50, "max": 100},
	"white_collar": {"min": 80, "max": 150},
	"investor": {"min": 150, "max": 500}
}
#endregion
#region names
var first_names_common_m = [] #
var first_names_apocalypse_m = []#
var first_names_wasp_m = [] #
var first_names_afro_m = []#
var first_names_africa_m = []#
var first_names_italian_m = []#
var first_names_spanish_m = []#
var first_names_french_m = []#
var first_names_slavic_m = []#
var first_names_nordic_m = []#
var first_names_chinese_m = []#
var first_names_indian_m = []#
var first_names_arab_m = []#
var first_names_japanese_m = []#
var first_names_korean_m = []#
var first_names_pacific_m = []#

var first_names_common_f = []#
var first_names_apocalypse_f = []#
var first_names_wasp_f = []#
var first_names_afro_f = []#
var first_names_africa_f = []
var first_names_spanish_f = []#
var first_names_french_f = []#
var first_names_italian_f = []#
var first_names_slavic_f = []#
var first_names_nordic_f = []#
var first_names_chinese_f = []#
var first_names_indian_f = []#
var first_names_arab_f = []#
var first_names_japanese_f = []#
var first_names_korean_f = []#
var first_names_pacific_f = []#

var last_names_common = []#
var last_names_apocalypse = []#
var last_names_wasp = []#
var last_names_africa = []#
var last_names_spanish = []#
var last_names_french = []#
var last_names_italian = []#
var last_names_slavic_m = []#
var last_names_slavic_f = []#
var last_names_nordic = []#
var last_names_chinese = []#
var last_names_indian = []#
var last_names_japanese = []#
var last_names_korean = []#
var last_names_arab = []#
var last_names_pacific = []#
#endregion

var hometowns_urban = []
var hometowns_rural = []
var town_weight_chance = 0.54 #54% urbanization rate

func _ready():
	randomize()
	initialize_name_lists()
	generate_players(2000)
	give_file_report()
	export_to_csv()
	

func load_csv_to_array(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	var array: Array = []
	
	if file:
		var content = file.get_as_text()
		file.close()
		if content.begins_with("{"):# Check if it's RTF format (starts with {)
			var end_brace_pos = content.find("}")
			if end_brace_pos != -1:
				content = content.substr(end_brace_pos + 1)
		var items = content.split(",")
		for item in items:
			var clean_item = item.strip_edges()
			if clean_item != "":
				array.append(clean_item)
	return array

func initialize_name_lists():
	first_names_common_m = load_csv_to_array("res://Assets/Gen Names/first_common_m.txt")
	first_names_apocalypse_m = load_csv_to_array("res://Assets/Gen Names/first_apocalypse_m.txt")
	first_names_wasp_m = load_csv_to_array("res://Assets/Gen Names/first_wasp_m.txt")
	first_names_afro_m = load_csv_to_array("res://Assets/Gen Names/first_afro_m.txt")
	first_names_africa_m = load_csv_to_array("res://Assets/Gen Names/first_africa_m.txt")
	first_names_italian_m = load_csv_to_array("res://Assets/Gen Names/first_italian_m.txt")
	first_names_spanish_m = load_csv_to_array("res://Assets/Gen Names/first_spanish_m.txt")
	first_names_french_m = load_csv_to_array("res://Assets/Gen Names/first_french_m.txt")
	first_names_slavic_m = load_csv_to_array("res://Assets/Gen Names/first_slavic_m.txt")
	first_names_nordic_m = load_csv_to_array("res://Assets/Gen Names/first_nordic_m.txt")
	first_names_chinese_m = load_csv_to_array("res://Assets/Gen Names/first_chinese_m.txt")
	first_names_indian_m = load_csv_to_array("res://Assets/Gen Names/first_indian_m.txt")
	first_names_japanese_m = load_csv_to_array("res://Assets/Gen Names/first_japanese_m.txt")
	first_names_korean_m = load_csv_to_array("res://Assets/Gen Names/first_korean_m.txt")
	first_names_pacific_m = load_csv_to_array("res://Assets/Gen Names/first_pacific_m.txt")
	first_names_common_f = load_csv_to_array("res://Assets/Gen Names/first_common_f.txt")
	first_names_apocalypse_f = load_csv_to_array("res://Assets/Gen Names/first_apocalypse_f.txt")
	first_names_wasp_f = load_csv_to_array("res://Assets/Gen Names/first_wasp_f.txt")
	first_names_afro_f = load_csv_to_array("res://Assets/Gen Names/first_afro_f.txt")
	first_names_africa_f = load_csv_to_array("res://Assets/Gen Names/first_africa_f.txt")
	first_names_spanish_f = load_csv_to_array("res://Assets/Gen Names/first_spanish_f.txt")
	first_names_french_f = load_csv_to_array("res://Assets/Gen Names/first_french_f.txt")
	first_names_italian_f = load_csv_to_array("res://Assets/Gen Names/first_italian_f.txt")
	first_names_slavic_f = load_csv_to_array("res://Assets/Gen Names/first_slavic_f.txt")
	first_names_nordic_f = load_csv_to_array("res://Assets/Gen Names/first_nordic_f.txt")
	first_names_chinese_f = load_csv_to_array("res://Assets/Gen Names/first_chinese_f.txt")
	first_names_indian_f = load_csv_to_array("res://Assets/Gen Names/first_indian_f.txt")
	first_names_japanese_f = load_csv_to_array("res://Assets/Gen Names/first_japanese_f.txt")
	first_names_korean_f = load_csv_to_array("res://Assets/Gen Names/first_korean_f.txt")
	first_names_pacific_f = load_csv_to_array("res://Assets/Gen Names/first_pacific_f.txt")
	last_names_common = load_csv_to_array("res://Assets/Gen Names/last_common.txt")
	last_names_apocalypse = load_csv_to_array("res://Assets/Gen Names/last_apocalypse.txt")
	last_names_wasp = load_csv_to_array("res://Assets/Gen Names/last_wasp.txt")
	last_names_africa = load_csv_to_array("res://Assets/Gen Names/last_africa.txt")
	last_names_spanish = load_csv_to_array("res://Assets/Gen Names/last_spanish.txt")
	last_names_french = load_csv_to_array("res://Assets/Gen Names/last_french.txt")
	last_names_italian = load_csv_to_array("res://Assets/Gen Names/last_italian.txt")
	last_names_slavic_m = load_csv_to_array("res://Assets/Gen Names/last_slavic_m.txt")
	last_names_slavic_f = load_csv_to_array("res://Assets/Gen Names/last_slavic_f.txt")
	last_names_nordic = load_csv_to_array("res://Assets/Gen Names/last_nordic.txt")
	last_names_chinese = load_csv_to_array("res://Assets/Gen Names/last_chinese.txt")
	last_names_indian = load_csv_to_array("res://Assets/Gen Names/last_indian.txt")
	last_names_japanese = load_csv_to_array("res://Assets/Gen Names/last_japanese.txt")
	last_names_korean = load_csv_to_array("res://Assets/Gen Names/last_korean.txt")
	last_names_arab = load_csv_to_array("res://Assets/Gen Names/last_arab.txt")
	last_names_pacific = load_csv_to_array("res://Assets/Gen Names/last_pacific.txt")
	hometowns_urban = load_csv_to_array("res://Assets/Gen Names/hometowns_urban.txt")
	hometowns_rural = load_csv_to_array("res://Assets/Gen Names/hometowns_rural.txt")

func generate_players(num: int):
	characters.clear()
	
	for i in range(num):
		var character = Character.new()
		var player = Player.new()
		var gender = determine_gender(true)
		character.gender = gender
		player.bio.leftHanded = randf() < left_hand_frequency
		player.bio.years = randi_range(min_player_age, max_player_age)
		
		# Generate names
		var names = generate_random_names(gender)
		names = mix_match_names(names, gender)
		player.bio.first_name = names[0]
		player.bio.last_name = names[1]
		
		var physical = generate_physical_attributes(gender)
		player.bio.feet = physical["feet"]
		player.bio.inches = physical["inches"]
		player.bio.pounds = physical["weight"]
		
		player.bio.hometown = generate_hometown()
		
		var primary_position = weighted_random_choice(position_frequency)
		player.preferred_position = primary_position
		player.field_position = primary_position
		player.playable_positions = generate_playable_positions(primary_position)
		
		generate_attributes(player, gender, physical["height_inches"], physical["weight"], physical["category"])
		player.calculate_player_type()
		character.player = player
		characters.append(character)

func determine_gender(is_player: bool) -> String:
	var rand_gender = randf()
	
	if is_player:
		if rand_gender < male_frequency_players:
			return "m"
		elif rand_gender < male_frequency_players + intersex_frequency:
			return "i"
		else:
			return "f"
	else:
		if rand_gender < male_frequency_general:
			return "m"
		elif rand_gender < male_frequency_general + intersex_frequency:
			return "i"
		else:
			return "f"

func generate_physical_attributes(gender: String) -> Dictionary:
	var height_data = height_distribution["male"] if gender == "m" else height_distribution["female"]
	var height_inches: int
	
	# Generate height with normal distribution
	var attempts = 0
	while attempts < 100:
		var u1 = randf()
		var u2 = randf()
		var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
		
		height_inches = int(height_data["avg"] + z0 * height_data["std_dev"])
		
		if height_inches >= height_data["min"] and height_inches <= height_data["max"]:
			break
		attempts += 1
	
	if attempts >= 100:
		height_inches = randi_range(height_data["min"], height_data["max"])
	
	var feet = height_inches / 12
	var inches = height_inches % 12
	
	# Generate weight category
	var weight_category = generate_weight_category_for_player()
	var category_data = weight_categories[weight_category]
	
	var height_meters = height_inches * 0.0254
	var min_bmi_weight = category_data["bmi_range"]["min"] * height_meters * height_meters * 2.20462
	var max_bmi_weight = category_data["bmi_range"]["max"] * height_meters * height_meters * 2.20462
	
	var min_weight = max(category_data["weight_range"]["min"], min_bmi_weight, 90)
	var max_weight = min(category_data["weight_range"]["max"], max_bmi_weight, 350)
	min_weight = min(min_weight, max_weight)
	max_weight = max(min_weight, max_weight)
	
	var weight = randi_range(int(min_weight), int(max_weight))
	
	return {
		"height_inches": height_inches,
		"feet": feet,
		"inches": inches,
		"weight": weight,
		"category": weight_category
	}

func generate_weight_category_for_player() -> String:
	var adjusted_frequencies = {}
	var total_weight = 0.0
	
	for category in weight_categories:
		var base_freq = weight_categories[category]["frequency"]
		var player_adjustment = player_weight_frequency_adjustment.get(category, 1.0)
		var adjusted_freq = base_freq * player_adjustment
		adjusted_frequencies[category] = adjusted_freq
		total_weight += adjusted_freq
	
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	
	for category in adjusted_frequencies:
		cumulative += adjusted_frequencies[category]
		if rand_value <= cumulative:
			return category
	
	return "old_world"

func weighted_random_choice(weight_dict: Dictionary):
	var total_weight = 0.0
	for weight in weight_dict.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_sum = 0.0
	
	for key in weight_dict.keys():
		current_sum += weight_dict[key]
		if random_value <= current_sum:
			return key
	
	return weight_dict.keys()[0]

func generate_random_names(passed_gender: String) -> Array:
	var first_name_category = weighted_random_choice(name_frequency_first)
	var first_name = ""
	var gender = passed_gender
	if passed_gender == "i":
		if randf() < 0.5:
			gender = "m"
		else:
			gender = "f"
	
	match first_name_category:
		"common":
			var array = first_names_common_m if gender == "m" else first_names_common_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"apocalypse":
			var array = first_names_apocalypse_m if gender == "m" else first_names_apocalypse_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"afro":
			var array = first_names_afro_m if gender == "m" else first_names_afro_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"spanish":
			var array = first_names_spanish_m if gender == "m" else first_names_spanish_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"french":
			var array = first_names_french_m if gender == "m" else first_names_french_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"italian":
			var array = first_names_italian_m if gender == "m" else first_names_italian_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"slavic":
			var array = first_names_slavic_m if gender == "m" else first_names_slavic_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"arab":
			var array = first_names_arab_m if gender == "m" else first_names_arab_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"nordic":
			var array = first_names_nordic_m if gender == "m" else first_names_nordic_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"indian":
			var array = first_names_indian_m if gender == "m" else first_names_indian_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"japanese":
			var array = first_names_japanese_m if gender == "m" else first_names_japanese_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"chinese":
			var array = first_names_chinese_m if gender == "m" else first_names_chinese_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"korean":
			var array = first_names_korean_m if gender == "m" else first_names_korean_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"wasp":
			var array = first_names_wasp_m if gender == "m" else first_names_wasp_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"africa":
			var array = first_names_africa_m if gender == "m" else first_names_africa_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"pacific":
			var array = first_names_pacific_m if gender == "m" else first_names_pacific_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
	
	var last_name_category = weighted_random_choice(name_frequency_last)
	var last_name = ""
	
	match last_name_category:
		"common":
			last_name = last_names_common[randi() % last_names_common.size()] if last_names_common.size() > 0 else "Unknown"
		"italian":
			last_name = last_names_italian[randi() % last_names_italian.size()] if last_names_italian.size() > 0 else "Unknown"
		"apocalypse":
			last_name = last_names_apocalypse[randi() % last_names_apocalypse.size()] if last_names_apocalypse.size() > 0 else "Unknown"
		"spanish":
			last_name = last_names_spanish[randi() % last_names_spanish.size()] if last_names_spanish.size() > 0 else "Unknown"
		"french":
			last_name = last_names_french[randi() % last_names_french.size()] if last_names_french.size() > 0 else "Unknown"
		"slavic":
			var array = last_names_slavic_m if gender == "m" else last_names_slavic_f
			last_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
		"nordic":
			var array = last_names_nordic
		"indian":
			last_name = last_names_indian[randi() % last_names_indian.size()] if last_names_indian.size() > 0 else "Unknown"
		"arab":
			last_name = last_names_arab[randi() % last_names_arab.size()] if last_names_arab.size() > 0 else "Unknown"
		"japanese":
			last_name = last_names_japanese[randi() % last_names_japanese.size()] if last_names_japanese.size() > 0 else "Unknown"
		"chinese":
			last_name = last_names_chinese[randi() % last_names_chinese.size()] if last_names_chinese.size() > 0 else "Unknown"
		"korean":
			last_name = last_names_korean[randi() % last_names_korean.size()] if last_names_korean.size() > 0 else "Unknown"
		"wasp":
			last_name = last_names_wasp[randi() % last_names_wasp.size()] if last_names_wasp.size() > 0 else "Unknown"
		"africa":
			last_name = last_names_africa[randi() % last_names_africa.size()] if last_names_africa.size() > 0 else "Unknown"
		"pacific":
			last_name = last_names_pacific[randi() % last_names_pacific.size()] if last_names_pacific.size() > 0 else "Unknown"
	
	return [first_name, last_name, last_name_category]

func mix_match_names(names: Array, gender: String) -> Array:
	var last_name_category = names[2]
	var category_map = {
		"common": "common",
		"italian": "italian",
		"apocalypse": "apocalypse",
		"spanish": "spanish",
		"french": "french",
		"slavic": "slavic",
		"nordic": "nordic",
		"indian": "indian",
		"arab": "arab",
		"japanese": "japanese",
		"chinese": "chinese",
		"korean": "korean",
		"wasp": "wasp",
		"africa": "africa",
		"pacific": "pacific"
	}
	
	if category_map.has(last_name_category):
		var first_name_category = category_map[last_name_category]
		if mix_fix_chance.has(first_name_category):
			var chance = mix_fix_chance[first_name_category]
			if randf() < chance:
				var first_name = ""
				match first_name_category:
					"common":
						var array = first_names_common_m if gender == "m" else first_names_common_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"apocalypse":
						var array = first_names_apocalypse_m if gender == "m" else first_names_apocalypse_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"spanish":
						var array = first_names_spanish_m if gender == "m" else first_names_spanish_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"french":
						var array = first_names_french_m if gender == "m" else first_names_french_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"italian":
						var array = first_names_italian_m if gender == "m" else first_names_italian_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"slavic":
						var array = first_names_slavic_m if gender == "m" else first_names_slavic_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"nordic":
						var array = first_names_nordic_m if gender == "m" else first_names_nordic_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"indian":
						var array = first_names_indian_m if gender == "m" else first_names_indian_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"japanese":
						var array = first_names_japanese_m if gender == "m" else first_names_japanese_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"chinese":
						var array = first_names_chinese_m if gender == "m" else first_names_chinese_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"korean":
						var array = first_names_korean_m if gender == "m" else first_names_korean_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"wasp":
						var array = first_names_wasp_m if gender == "m" else first_names_wasp_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"africa":
						var array = first_names_africa_m if gender == "m" else first_names_africa_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
					"pacific":
						var array = first_names_pacific_m if gender == "m" else first_names_pacific_f
						first_name = array[randi() % array.size()] if array.size() > 0 else names[0]
				
				if first_name != "":
					names[0] = first_name
	
	return [names[0], names[1]]

func generate_hometown() -> String:
	var town = ""
	if randf() < town_weight_chance:#urban
		if hometowns_urban.size() > 0:
			town = hometowns_urban[randi() % hometowns_urban.size()]
		else:
			town = "Unknown"
	else:#rural
		if hometowns_rural.size() > 0:
			town = hometowns_rural[randi() % hometowns_rural.size()]
		else:
			town = "Unknown"
	return town

func generate_playable_positions(primary: String) -> Array:
	var positions = [primary]
	var all_positions = ["P", "K", "LG", "RG", "LF", "RF"]
	all_positions.erase(primary)
	var num_positions = 1
	var rand_val = randf()
	var cumulative = 0.0
	
	for count in multi_position_frequency.keys():
		cumulative += multi_position_frequency[count]
		if rand_val <= cumulative:
			num_positions = count
			break
	
	for i in range(num_positions - 1):
		if all_positions.size() == 0:
			break
		var weights = {}
		for pos in all_positions:
			var weight = 1.0
			if primary in ["LG", "RG"] and pos in ["LG", "RG"]:
				weight = 3.0
			elif primary in ["LF", "RF"] and pos in ["LF", "RF"]:
				weight = 3.0
			elif primary == "LF" and pos == "LG":
				weight = 2.0
			elif primary == "RF" and pos == "RG":
				weight = 2.0
			elif primary == "LG" and pos == "LF":
				weight = 2.0
			elif primary == "RG" and pos == "RF":
				weight = 2.0
			elif primary == "K" and pos in ["LG", "RG"]:
				weight = 1.5
			weights[pos] = weight * position_frequency.get(pos, 0.138)
		var chosen_pos = weighted_random_choice(weights)
		positions.append(chosen_pos)
		all_positions.erase(chosen_pos)
	
	return positions

func generate_attributes(player: Player, gender: String, height_inches: int, weight: float, weight_category: String):
	var attributes = {
		"speedRating": randi_range(15, 85),
		"speed": 110.0,
		"sprint_speed": 140.0,
		"blocking": randi_range(15, 85),
		"positioning": randi_range(15, 85),
		"aggression": randi_range(15, 85),
		"reactions": randi_range(15, 85),
		"durability": randi_range(15, 85),
		"power": randi_range(15, 85),
		"throwing": randi_range(15, 85),
		"endurance": randi_range(15, 85),
		"accuracy": randi_range(15, 85),
		"balance": randi_range(15, 85),
		"focus": randi_range(15, 85),
		"shooting": randi_range(15, 85),
		"toughness": randi_range(15, 85),
		"confidence": randi_range(15, 85),
		"agility": randi_range(15, 85),
		"faceoffs": randi_range(15, 85),
		"discipline": randi_range(15, 85)
	}
	apply_physical_modifiers(attributes, height_inches, weight_category)
	apply_position_base_adjustments(attributes, player.preferred_position)
	var style = generate_player_style(player.preferred_position, attributes)
	apply_style_adjustments(attributes, style, player.preferred_position)
	var overall = weighted_random_choice(player_overall_rates)
	scale_attributes_to_overall_with_variance(player, attributes, style, overall)
	for key in attributes.keys():
		if key != "speed" and key != "sprint_speed":
			attributes[key] = clamp(int(attributes[key]), 1, 100)
	attributes.speed = attributes.speedRating + 35
	attributes.sprint_speed = (attributes.speedRating - 5) * 2
	player.attributes = attributes

func apply_physical_modifiers(attributes: Dictionary, height_inches: int, weight_category: String):
	var height_data = height_distribution["male"]
	var height_factor = float(height_inches - height_data["min"]) / float(height_data["max"] - height_data["min"])
	height_factor = clamp(height_factor, 0.0, 1.0)
	
	for modifier in HEIGHT_MODIFIERS:
		if attributes.has(modifier):
			var adjustment = HEIGHT_MODIFIERS[modifier] * (height_factor * 20)
			attributes[modifier] += adjustment
	
	if WEIGHT_CATEGORY_MODIFIERS.has(weight_category):
		var category_modifiers = WEIGHT_CATEGORY_MODIFIERS[weight_category]
		for modifier in category_modifiers:
			if attributes.has(modifier):
				attributes[modifier] += category_modifiers[modifier]

func apply_position_base_adjustments(attributes: Dictionary, position: String):
	match position:
		"P":
			attributes.power += randi_range(5, 20)
			attributes.throwing += randi_range(5, 20)
			attributes.focus += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
			attributes.faceoffs += randi_range(5, 20)
		"K":
			attributes.blocking += randi_range(5, 20)
			attributes.positioning += randi_range(5, 20)
			attributes.reactions += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
		"LG", "RG":
			attributes.power += randi_range(5, 20)
			attributes.positioning += randi_range(5, 20)
			attributes.blocking += randi_range(5, 20)
			attributes.balance += randi_range(5, 20)
		"LF", "RF":
			attributes.shooting += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
			attributes.agility += randi_range(5, 20)

func generate_player_style(position: String, attributes: Dictionary) -> String:
	match position:
		"P":
			return weighted_random_choice(pitcher_styles)
		"K":
			return weighted_random_choice(keeper_styles)
		"LF", "RF":
			return weighted_random_choice(forward_styles)
		
		"LG", "RG":
			return weighted_random_choice(guard_styles)
	
	return "Standing"

func apply_style_adjustments(attributes: Dictionary, style: String, position: String):
	match style:
		"Ace":
			attributes.throwing += randi_range(5, 20)
			attributes.faceoffs += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
			attributes.focus += randi_range(5, 20)
		"Workhorse":
			attributes.endurance += randi_range(5, 20)
			attributes.durability += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
			attributes.balance += randi_range(5, 20)
		"Hatchet Man":
			attributes.throwing += randi_range(5, 20)
			attributes.toughness += randi_range(5, 25)
			attributes.aggression += randi_range(5, 20)
			attributes.power += randi_range(5, 20)
		"Track Hog":
			attributes.faceoffs += randi_range(5, 20)
			attributes.toughness += randi_range(5, 20)
			attributes.aggression += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
		"Acrobatic":
			attributes.agility += randi_range(5, 20)
			attributes.reactions += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
		"Crouching":
			attributes.endurance += randi_range(5, 20)
			attributes.balance += randi_range(5, 20)
			attributes.durability += randi_range(5, 20)
		"Kneeling":
			attributes.focus += randi_range(5, 20)
			attributes.confidence += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
		"Standing":
			attributes.power += randi_range(5, 20)
			attributes.blocking += randi_range(5, 20)
			attributes.aggression += randi_range(5, 20)
		"Goal Scorer":
			attributes.shooting += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
		"Anti-Keeper":
			attributes.power += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
			attributes.endurance += randi_range(5, 20)
		"Support Forward":
			attributes.positioning += randi_range(5, 20)
			attributes.power += randi_range(5, 20)
			attributes.accuracy += randi_range(5, 20)
		"Skull Cracker":
			attributes.toughness += randi_range(5, 20)
			attributes.aggression += randi_range(5, 20)
			attributes.power += randi_range(5, 20)
		"Ball Hound":
			attributes.reactions += randi_range(5, 20)
			attributes.shooting += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
		"Defender":
			attributes.positioning += randi_range(5, 20)
			attributes.speedRating += randi_range(5, 20)
			attributes.endurance += randi_range(5, 20)
		"Bully":
			attributes.power += randi_range(5, 20)
			attributes.toughness += randi_range(5, 20)
			attributes.aggression += randi_range(5, 20)

func scale_attributes_to_overall_with_variance(player: Player, attributes: Dictionary, style: String, target_overall: int):
	player.attributes = attributes
	var current_overall = player.calculate_overall()
	var key_attributes = get_key_attributes_for_role(style)
	var all_attributes = attributes.keys()
	var non_key_attributes = []
	for attr in all_attributes:
		if attr not in key_attributes and attr not in ["speed", "sprint_speed"]:
			non_key_attributes.append(attr)
	var attempts = 0
	var max_attempts = 150
	
	while abs(current_overall - target_overall) > 2 and attempts < max_attempts:
		if current_overall < target_overall:
			var random_key_attr = key_attributes[randi() % key_attributes.size()]
			var boost_amount = randi_range(2, 10)
			attributes[random_key_attr] += boost_amount
			attributes[random_key_attr] = min(attributes[random_key_attr], 100)
			if non_key_attributes.size() > 0 and randf() < 0.3:
				var random_non_key_attr = non_key_attributes[randi() % non_key_attributes.size()]
				var small_variance = randi_range(-3, 3)
				attributes[random_non_key_attr] += small_variance
				attributes[random_non_key_attr] = clamp(attributes[random_non_key_attr], 1, 100)
		else:
			if non_key_attributes.size() > 0:
				var random_non_key_attr = non_key_attributes[randi() % non_key_attributes.size()]
				var reduce_amount = randi_range(2, 10)
				attributes[random_non_key_attr] -= reduce_amount
				attributes[random_non_key_attr] = max(attributes[random_non_key_attr], 1)
			if randf() < 0.2:
				var random_key_attr = key_attributes[randi() % key_attributes.size()]
				var small_variance = randi_range(-2, 2)
				attributes[random_key_attr] += small_variance
				attributes[random_key_attr] = clamp(attributes[random_key_attr], 1, 100)
		player.attributes = attributes
		current_overall = player.calculate_overall()
		attempts += 1

func get_key_attributes_for_role(role: String) -> Array:
	match role:
		"Ace":
			return ["power", "throwing", "focus", "accuracy", "confidence"]
		"Workhorse":
			return ["endurance", "confidence", "accuracy", "power", "throwing", "focus"]
		"Hatchet Man":
			return ["toughness", "shooting", "power", "speedRating", "durability", "balance"]
		"Track Hog":
			return ["reactions", "faceoffs", "accuracy", "speedRating"]
		"Acrobatic":
			return ["agility", "reactions", "speedRating"]
		"Crouching":
			return ["endurance", "balance", "durability"]
		"Kneeling":
			return ["focus", "confidence", "accuracy"]
		"Standing":
			return ["power", "blocking", "aggression"]
		"Goal Scorer":
			return ["shooting", "accuracy", "speedRating"]
		"Anti-Keeper":
			return ["power", "speedRating", "endurance"]
		"Support Forward":
			return ["positioning", "power", "accuracy"]
		"Skull Cracker":
			return ["toughness", "aggression", "power"]
		"Ball Hound":
			return ["reactions", "shooting", "speedRating"]
		"Defender":
			return ["positioning", "speedRating", "endurance"]
		"Bully":
			return ["power", "toughness", "aggression"]
		_:
			return ["speedRating", "power", "shooting", "accuracy"]

func get_day_job() -> Dictionary:
	if randf() < unemployment_rate:
		return {"job": "none", "pay": 0}
	if randf() < subsistence_farmer_rate:
		return {"job": "farm", "pay": randi_range(5, 15)}
	var industry = weighted_random_choice(job_rates)
	var social_class = weighted_random_choice(class_distribution)
	var job_title = job_titles[industry][social_class]
	
	var pay_range = job_pay_ranges[social_class]
	var pay = randi_range(pay_range["min"], pay_range["max"])
	
	return {"job": job_title, "pay": pay}

func get_favorite_food() -> String:
	var all_foods = ["bbq", "island", "casserole", "mexican", "vegetarian"]
	return all_foods.pick_random()

func export_to_csv(file_path: String = "res://Assets/Rosters/roster_export.csv"):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("Error: Could not open file for writing: ", file_path)
		return
	
	# Header
	file.store_line("first_name,last_name,nickname,hometown,left_handed,feet,inches,pounds,years,speed_rating,blocking,positioning,aggression,reactions,durability,power,throwing,endurance,accuracy,balance,focus,shooting,toughness,confidence,agility,faceoffs,discipline,playable_positions,preferred_position,declared_pitcher,special_pitches,pitch_grooves,portrait,head,haircut,glove,shoe,body_type,skin_tone_primary,skin_tone_secondary,complexion,best_league,play_style,gender,attracted,gang,home_cooking,day_job,day_job_pay,spouses,children,elders,adults,positivity,negativity,influence,promiscuity,loyalty,love_of_the_game,professionalism,partying,potential,hustle,hardiness,combat,franchise_id,contract_type,seasons_left,salary,revenue_share,water,food,buyout,housing,tryout_games,preferred_job,job_roles,contract_focus_value,contract_focus_stability,contract_focus_flexibility,contract_focus_satiety,contract_focus_hydration,contract_focus_hometown,contract_focus_housing,contract_focus_house_type,contract_focus_gameday,contract_focus_travel,contract_focus_medical,contract_focus_party,contract_focus_chill,contract_focus_win_now,contract_focus_win_later,contract_focus_loyalty,contract_focus_opportunity,contract_focus_community,contract_focus_development,contract_focus_safety,contract_focus_education,contract_focus_trade,contract_focus_farming,contract_focus_day_life,contract_focus_night_life,contract_focus_welfare,physical_training,technical_training,mental_training,talent_eval,talent_spotting,scouting_speed,deescalation,anti_banditry,escorting,trauma,ortho,medicine,stretching,first_aid,rehab,attraction,sponsorship,networking,masonry,carpentry,painting,sewing,carrying,acquisitions,line_cooking,home_cooking,fine_cooking,auditing,budgeting,bidding,raging,chilling,intimacy,charisma,helpfulness,longevity")
	
	# Write each player
	for character in characters:
		var player = character.player
		var line_parts = []
		
		# Basic info (fields 1-27)
		line_parts.append(player.bio.first_name)
		line_parts.append(player.bio.last_name)
		line_parts.append("")  # nickname
		line_parts.append(player.bio.hometown)
		line_parts.append("TRUE" if player.bio.leftHanded else "FALSE")
		line_parts.append(str(player.bio.feet))
		line_parts.append(str(player.bio.inches))
		line_parts.append(str(player.bio.pounds))
		line_parts.append(str(player.bio.years))
		line_parts.append(str(player.attributes.speedRating))
		line_parts.append(str(player.attributes.blocking))
		line_parts.append(str(player.attributes.positioning))
		line_parts.append(str(player.attributes.aggression))
		line_parts.append(str(player.attributes.reactions))
		line_parts.append(str(player.attributes.durability))
		line_parts.append(str(player.attributes.power))
		line_parts.append(str(player.attributes.throwing))
		line_parts.append(str(player.attributes.endurance))
		line_parts.append(str(player.attributes.accuracy))
		line_parts.append(str(player.attributes.balance))
		line_parts.append(str(player.attributes.focus))
		line_parts.append(str(player.attributes.shooting))
		line_parts.append(str(player.attributes.toughness))
		line_parts.append(str(player.attributes.confidence))
		line_parts.append(str(player.attributes.agility))
		line_parts.append(str(player.attributes.faceoffs))
		line_parts.append(str(player.attributes.discipline))
		
		# Fields 28-32 - Wrap comma-separated positions in quotes
		line_parts.append(csv_escape(",".join(player.playable_positions)))
		line_parts.append(player.preferred_position)
		line_parts.append("TRUE" if player.declared_pitcher else "FALSE")
		line_parts.append("")  # special_pitches
		line_parts.append("")  # pitch_grooves
		
		# Appearance fields 33-41 (9 fields)
		for i in range(9):
			line_parts.append("")
		
		# Character info fields 42-49 (8 fields)
		line_parts.append("")  # best_league
		line_parts.append(csv_escape(player.playStyle))
		line_parts.append(character.gender)
		line_parts.append("")  # attracted
		
		# Gang affiliation
		var gang = ""
		if randf() < gang_rate:
			gang = gangs[randi() % gangs.size()]
		character.gang_affiliation = gang
		line_parts.append(csv_escape(gang))
		
		# Home cooking and day job (fields 50-52)
		line_parts.append(get_favorite_food())
		var day_job_info = get_day_job()
		line_parts.append(csv_escape(day_job_info["job"]))
		line_parts.append(str(day_job_info["pay"]))
		
		# Family counts fields 53-56 (4 fields)
		for i in range(4):
			line_parts.append("")
		
		# Off attributes fields 57-68 (12 fields)
		for i in range(12):
			line_parts.append("")
		
		# Contract and franchise info fields 69-77 (9 fields)
		for i in range(9):
			line_parts.append("")
		
		# Additional fields: preferred_job and job_roles (fields 78-79)
		line_parts.append("")  # preferred_job
		line_parts.append("")  # job_roles
		
		# Contract focuses fields 80-103 (24 fields)
		for i in range(24):
			line_parts.append("")
		
		# Staff skills fields 104-138 (35 fields)
		for i in range(35):
			line_parts.append("")
		
		# Final safety check
		if line_parts.size() != 138:
			print("Warning: Player %s %s has %d fields, expected 138" % [player.bio.first_name, player.bio.last_name, line_parts.size()])
			while line_parts.size() < 138:
				line_parts.append("")
			if line_parts.size() > 138:
				line_parts.resize(138)
		
		file.store_line(",".join(line_parts))
	
	file.close()
	print("Exported ", characters.size(), " characters to ", file_path)

# Add this helper function for proper CSV escaping
func csv_escape(value: String) -> String:
	if value.is_empty():
		return ""
	
	# If the value contains comma, quote, or newline, wrap in quotes and escape internal quotes
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		return "\"" + value.replace("\"", "\"\"") + "\""
	
	return value

func give_file_report():
	print("\n=== CHARACTER GENERATION REPORT ===\n")
	
	if characters.size() == 0:
		print("No characters generated yet. Run generate_players() first.")
		return
	
	print("NAME ORIGIN STATISTICS:\n")
	var first_name_origins = {}
	for character in characters:
		var player = character.player
		var first_name = player.bio.first_name
		var origin = "unknown"
		if first_name in first_names_common_m or first_name in first_names_common_f:
			origin = "common"
		elif first_name in first_names_spanish_m or first_name in first_names_spanish_f:
			origin = "spanish"
		elif first_name in first_names_afro_m or first_name in first_names_afro_f:
			origin = "afro"
		elif first_name in first_names_apocalypse_m or first_name in first_names_apocalypse_f:
			origin = "apocalypse"
		elif first_name in first_names_wasp_m or first_name in first_names_wasp_f:
			origin = "wasp"
		elif first_name in first_names_africa_m or first_name in first_names_africa_f:
			origin = "africa"
		elif first_name in first_names_italian_m or first_name in first_names_italian_f:
			origin = "italian"
		elif first_name in first_names_french_m or first_name in first_names_french_f:
			origin = "french"
		elif first_name in first_names_slavic_m or first_name in first_names_slavic_f:
			origin = "slavic"
		elif first_name in first_names_nordic_m or first_name in first_names_nordic_f:
			origin = "nordic"
		elif first_name in first_names_chinese_m or first_name in first_names_chinese_f:
			origin = "chinese"
		elif first_name in first_names_indian_m or first_name in first_names_indian_f:
			origin = "indian"
		elif first_name in first_names_arab_m or first_name in first_names_arab_f:
			origin = "arab"
		elif first_name in first_names_japanese_m or first_name in first_names_japanese_f:
			origin = "japanese"
		elif first_name in first_names_korean_m or first_name in first_names_korean_f:
			origin = "korean"
		elif first_name in first_names_pacific_m or first_name in first_names_pacific_f:
			origin = "pacific"
		
		first_name_origins[origin] = first_name_origins.get(origin, 0) + 1
	
	print("First Name Origins:")
	for origin in first_name_origins:
		var percentage = float(first_name_origins[origin]) / characters.size() * 100
		print("  %-15s: %3d (%.1f%%)" % [origin, first_name_origins[origin], percentage])
	print("OVERALL RATINGS BY POSITION:\n")
	
	var position_stats = {
		"K": {"count": 0, "total": 0, "ranges": {}},
		"LF": {"count": 0, "total": 0, "ranges": {}},
		"RF": {"count": 0, "total": 0, "ranges": {}},
		"LG": {"count": 0, "total": 0, "ranges": {}},
		"RG": {"count": 0, "total": 0, "ranges": {}},
		"P": {"count": 0, "total": 0, "ranges": {}}
	}
	
	var range_names = ["Non-player (0-50)", "Fringe (50-60)", "B (61-70)", "A (71-80)", "AA (81-90)", "AAA (91+)"]
	for pos in position_stats:
		for range_name in range_names:
			position_stats[pos]["ranges"][range_name] = 0
	
	for character in characters:
		var player = character.player
		var overall = player.calculate_overall()
		var range_name = ""
		if overall <= 50:
			range_name = "Non-player (0-50)"
		elif overall <= 60:
			range_name = "Fringe (50-60)"
		elif overall <= 70:
			range_name = "B (61-70)"
		elif overall <= 80:
			range_name = "A (71-80)"
		elif overall <= 90:
			range_name = "AA (81-90)"
		else:
			range_name = "AAA (91+)"
		
		for position in player.playable_positions:
			if position_stats.has(position):
				position_stats[position]["count"] += 1
				position_stats[position]["total"] += overall
				position_stats[position]["ranges"][range_name] += 1
	
	for position in ["K", "LF", "RF", "LG", "RG", "P"]:
		var stats = position_stats[position]
		if stats["count"] > 0:
			var avg = float(stats["total"]) / stats["count"]
			print("\n%s (Total: %d, Avg: %.1f):" % [position, stats["count"], avg])
			
			for range_name in range_names:
				var count = stats["ranges"][range_name]
				if count > 0:
					var percentage = float(count) / stats["count"] * 100
					print("  %-20s: %3d (%.1f%%)" % [range_name, count, percentage])
	
	# Overall distribution
	print("\nOVERALL DISTRIBUTION:")
	print("\n")
	
	var overall_ranges = {}
	for range_name in range_names:
		overall_ranges[range_name] = 0
	
	for character in characters:
		var player = character.player
		var overall = player.calculate_overall()
		
		if overall <= 50:
			overall_ranges["Non-player (0-50)"] += 1
		elif overall <= 60:
			overall_ranges["Fringe (50-60)"] += 1
		elif overall <= 70:
			overall_ranges["B (61-70)"] += 1
		elif overall <= 80:
			overall_ranges["A (71-80)"] += 1
		elif overall <= 90:
			overall_ranges["AA (81-90)"] += 1
		else:
			overall_ranges["AAA (91+)"] += 1
	
	for range_name in range_names:
		var count = overall_ranges[range_name]
		var percentage = float(count) / characters.size() * 100
		print("%-20s: %3d (%.1f%%)" % [range_name, count, percentage])
	
	print("\n")
	print("Total Characters Generated: ", characters.size())

func generate_player() -> Player:
	generate_players(1)
	return characters[0] if characters.size() > 0 else null

func generate_and_save_players(num: int) -> Array:
	generate_players(num)
	return characters

func get_player_info(player: Player) -> String:
	var info = "Name: %s %s\n" % [player.bio.first_name, player.bio.last_name]
	info += "Age: %d, Hometown: %s\n" % [player.bio.years, player.bio.hometown]
	info += "Height: %d'%d\", Weight: %d lbs, Left-handed: %s\n" % [
		player.bio.feet, player.bio.inches, player.bio.pounds,
		player.bio.leftHanded
	]
	info += "Primary Position: %s, Playable Positions: %s\n" % [player.field_position, str(player.playable_positions)]
	info += "Player Style: %s\n" % [player.playStyle]
	info += "Overall: %d\n" % [player.calculate_overall()]
	return info

func clear_players():
	characters.clear()

func generate_contract_focues(character: Character):
	var focuses = {}
	var adjusted_weights = adjust_focuses_for_character(character)
	var key_focus = weighted_random_choice(adjusted_weights)
	#TODO: set key focus to 2 in focuses to start
	var top_seven_focuses #TODO: get the top seven focuses 
	#TODO: if key focus is in there, add randf_range(-0.5,2) to it
	#TODO: assign all other focuses value of randf_range(0.1,4)
	#TODO: for all values below top 7:
	#	if randf() < 0.5:
	#		TODO: assign value of randf_range(0.1,2)
	
func adjust_focuses_for_character(character: Character):
	other_contract_focus_frequency #TODO: apply weight adjustments based on character
	pass
	
func assign_preferred_housing_type(character: Character):
	var adjusted_weights #TODO: adjust weights of housing type based on character and character.player
	var housing_type = weighted_random_choice(adjusted_weights)
	character.contract_focuses.house_type = housing_type


func generate_job_skills(character: Character, isPlayer: bool = false):
	var max_overall = min(character.player.bio.age,50)/50 * 860 #experience is everything for staff skills
	var staff_overall = randi_range(215, max_overall)
	if isPlayer:
		staff_overall = int(staff_overall * 0.8)
	var character_type = weighted_random_choice(non_player_type_frequency)
	match character_type: #TODO: assign attribute points to relevant attributes to type first, randomly assign remaining attributes, making sure no attributes are higher than relevant ones
		_:
			pass
	
func determine_number_of_spouses(age:int):
	if age <= 14:
		return 0 #even in the apocalypse we're not doing child marriages
	elif age in [15,16,17]:
		if randf() < 0.05:
			return 1
		else:
			return 0
	elif age <= 25:
		if randf() < 0.01:
			return 2
		elif randf() < 0.23:
			return 1
		else:
			return 0
	elif age <= 30:
		if randf() < 0.53:
			if randf() < 0.146:
				if randf() < 0.146:
					return 3
				return 2
			return 1
		return 0
	elif age <= 45:
		if randf() < 0.61:
			if randf() < 0.146:
				if randf() < 0.146:
					return 3
				return 2
			return 1
		return 0
	else:
		if randf() <= 0.5: #by this age you're lucky to have a spouse living at all in this world
			return 1
		return 0
		
func generate_family_members(num_spouses: int, age: int):
	var children
	var adults
	var elders
	if age < 20: #assuming 1991 levels of teen pregnancy
		if randf() < 0.061:
			children = 1
		else:
			children = 0
	else:
		var child_odds = {1: 3, 2:1, 0: 1, 3: 0.5, 4: 0.5}
		if num_spouses == 0:
			if randf() < 0.15: #factoring in child mortality and 25% chance of having kid but no spouse
				children += weighted_random_choice(child_odds)
		elif num_spouses == 1:
			if randf() < 0.7: #factor in child mortality
				children += weighted_random_choice(child_odds)
		else:
			for spouse in num_spouses:
				if age <= 25:
					if randf() < 0.7:
						children += weighted_random_choice(child_odds)
				elif age <= 30:
					if randf() < 0.6:
						var children_with_spouse = weighted_random_choice(child_odds) * 2
						children+= children_with_spouse
				else:
					if randf() < 0.5:
						var children_with_spouse = weighted_random_choice(child_odds) * 3
						children+= children_with_spouse
	var num_roommates = 0
	for i in range(0,4): #up to 3 tag alongs
		if randf() < 0.2:
			var roommate_age_range = weighted_random_choice(rando_age_weights)
			var roommate_age
			match roommate_age_range:
				"0-4":
					roommate_age = randi_range(0,4)
				"5-9":
					roommate_age = randi_range(5,9)
				"10-14":
					roommate_age = randi_range(10,14)
				"15-19":
					roommate_age = randi_range(15,19)
				"20-24":
					roommate_age = randi_range(20,24)
				"25-39":
					roommate_age = randi_range(25,39)
				"30-34":
					roommate_age = randi_range(30,34)
				"35-39":
					roommate_age = randi_range(35,39)
				"40-44":
					roommate_age = randi_range(40,44)
				"45-49":
					roommate_age = randi_range(45,49)
				"50-54":
					roommate_age = randi_range(50,54)
				"55-59":
					roommate_age = randi_range(55,59)
				"60-64":
					roommate_age = randi_range(60,64)
				"65-69":
					roommate_age = randi_range(65,69)
				"70-74":
					roommate_age = randi_range(70,74)
				"75-110":
					roommate_age = randi_range(75,110)
			if roommate_age > age + 10:
				elders += 1
			elif roommate_age < age - 10 or roommate_age < 16:
				children += 1 
			else:
				adults += 1
		#TODO: attach these values to the character
	pass
