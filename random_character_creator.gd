extends Node
class_name randomCharacterGenerator

const MAX_ATTEMPTS = 400
var characters:= []
var characters_players: = []
var characters_staff:= []
var min_overall: int = 30
var max_overall: int = 99
var min_potential: int = 30
var max_potential: int = 99
var left_hand_frequency: float = 0.25
var male_frequency_players: float = 0.93 #percentage of player gens who are going to be male
var male_frequency_general: float = 0.44 #percentage of non-player characters who are going to be male
var intersex_frequency: float = 0.017 #percentage of players and non-player characters who will be intersex
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
	"fighting_coach": 6, #loves violent play
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
	"prostitute": 15, #good at intimacy, ok at raging and chilling
	"stripper": 25, #good at attraction, ok at intimacy and raging
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
	"common": 36,
	"apocalypse": 14,
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
	"common": 34,
	"italian": 9,
	"apocalypse": 14,
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

var pitch_type_frequency = {
		"fake_curve": 15,
		"zig-zag": 5,
		"knuckler": 10,
		"bouncer": 20,
		"looper": 10,
		"corker": 5,
		"yoyo": 5,
		"changeup": 15,
		"flutter": 5,
		"moonball": 2,
		"stop_go": 2,
		"none": 10,
}

var pitch_groove_frequency = {
	10: 1,
	15: 2,
	20: 4,
	25: 8,
	30: 16,
	35: 32,
	40: 64,
	45: 128,
	50: 256
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
	"stunted": { #-10 net
		"endurance": 5,
		"speedRating": 10,
		"agility": 10,
		"power": -10,
		"toughness": -10,
		"durability": -10,
		"balance": -5
	},
	"starving": { #-5 net
		"endurance": 10,
		"speedRating": 10,
		"agility": 10,
		"power": -10,
		"toughness": -10,
		"durability": -10,
		"balance": -5
	},
	"scrawny": { #0 net
		"endurance": 10,
		"speedRating": 10,
		"agility": 5,
		"power": -5,
		"toughness": -10,
		"durability": -5,
		"balance": -5
	},
	"lean": { #+5 net
		"endurance": 10,
		"speedRating": 5,
		"agility": 5,
		"power": -5,
		"toughness": -5,
		"durability": -5,
		"balance": 0
	},
	"old_world": { #0 net
		"endurance": 0,
		"speedRating": 0,
		"agility": 0,
		"power": 0,
		"toughness": 0,
		"durability": 0,
		"balance": 0
	},
	"built": { #+5 net
		"endurance": -3,
		"speedRating": -2,
		"agility": -5,
		"power": 5,
		"toughness": 5,
		"durability": 0,
		"balance": 5
	},
	"heavy": { #+10 net
		"endurance": -5,
		"speedRating": -5,
		"agility": -5,
		"power": 5,
		"toughness": 5,
		"durability": 10,
		"balance": 5
	},
	"stocky": { #+15 net
		"endurance": -5,
		"speedRating": -5,
		"agility": -5,
		"power": 10,
		"toughness": 5,
		"durability": 10,
		"balance": 5
	},
	"bulky": { #+20 net
		"endurance": -5,
		"speedRating": -5,
		"agility": -10,
		"power": 10,
		"toughness": 10,
		"durability": 10,
		"balance": 10
	},
	"huge": { #+25 net
		"endurance": -10,
		"speedRating": -5,
		"agility": -10,
		"power": 10,
		"toughness": 10,
		"durability": 15,
		"balance": 15
	},
	"colossal": { #+30 net
		"endurance": -10,
		"speedRating": -10,
		"agility": -10,
		"power": 15,
		"toughness": 15,
		"durability": 15,
		"balance": 15
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
	characters.clear()
	initialize_name_lists()
	generate_players(2000)
	generate_characters(2000)
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
				# Replace escaped apostrophes \' with actual apostrophes '
				clean_item = clean_item.replace("\\'", "'")
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

func generate_players(num: int, is_staff: bool = false):
	for i in range(num):
		var character = Character.new()
		var player = Player.new()
		# Staff use the general population gender split; footballers use the player split
		var gender = determine_gender(!is_staff)
		character.gender = gender
		player.bio.leftHanded = randf() < left_hand_frequency

		if is_staff:
			# Age is drawn from the general population distribution
			var age_range_key = weighted_random_choice(rando_age_weights)
			var parts = age_range_key.split("-")
			player.bio.years = randi_range(int(parts[0]), int(parts[1]))
		else:
			player.bio.years = randi_range(min_player_age, max_player_age)

		# Generate names with up to 3 retries to avoid "Unknown" or blank names
		var names = []
		var attempts = 0
		while attempts < 3:
			names = generate_random_names(gender)
			names = mix_match_names(names, gender)
			# Check if the names are valid (not "Unknown" or blank)
			if names[0] != "Unknown" and names[0] != "" and names[1] != "Unknown" and names[1] != "":
				break
			attempts += 1
		
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
		if "P" in player.playable_positions:
			player.special_pitch_names = generate_special_pitches()
			var grooves: Array[float] = []
			for j in range(0, 3):
					var groove = weighted_random_choice(pitch_groove_frequency)
					if player.preferred_position == "P":
						grooves.append(groove)
					else:
						var groove2 = weighted_random_choice(pitch_groove_frequency)
						grooves.append(groove + groove2)
			player.special_pitch_groove = grooves

		generate_attributes(player, gender, physical["height_inches"], physical["weight"], physical["category"], is_staff)
		player.calculate_player_type()
		character.player = player

		if is_staff:
			characters_staff.append(character)
		else:
			characters_players.append(character)
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

func generate_attributes(player: Player, gender: String, height_inches: int, weight: float, weight_category: String, is_staff: bool = false):
	var attributes = {
		"speedRating": randi_range(15, 85),
		"speed": 110.0,
		"sprint_speed": 140.0,
		"blocking": randi_range(25, 85),
		"positioning": randi_range(25, 85),
		"aggression": randi_range(25, 85),
		"reactions": randi_range(25, 85),
		"durability": randi_range(25, 85),
		"power": randi_range(25, 85),
		"throwing": randi_range(25, 85),
		"endurance": randi_range(25, 85),
		"accuracy": randi_range(25, 85),
		"balance": randi_range(25, 85),
		"focus": randi_range(25, 85),
		"shooting": randi_range(25, 85),
		"toughness": randi_range(25, 85),
		"confidence": randi_range(25, 85),
		"agility": randi_range(25, 85),
		"faceoffs": randi_range(25, 85),
		"discipline": randi_range(25, 85)
	}
	apply_physical_modifiers(attributes, height_inches, weight_category)
	apply_position_base_adjustments(attributes, player.preferred_position)
	var style = generate_player_style(player.preferred_position, attributes)
	apply_style_adjustments(attributes, style, player.preferred_position)
	var overall: int
	if is_staff:
		# Staff characters are not footballers: compress their overall into 20-55.
		# We still use the weighted table so the shape of the distribution is
		# preserved, but then remap linearly from [20,99] → [20,55].
		var raw_overall = weighted_random_choice(player_overall_rates)
		overall = int(20.0 + (float(raw_overall - 20) / 79.0) * 35.0)
		overall = clamp(overall, 20, 55)
	else:
		overall = weighted_random_choice(player_overall_rates)
	scale_attributes_to_overall_with_variance(player, attributes, style, overall)
	for key in attributes.keys():
		if key != "speed" and key != "sprint_speed":
			attributes[key] = clamp(int(attributes[key]), 1, 99)
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
	var max_attempts = MAX_ATTEMPTS
	
	while abs(current_overall - target_overall) > 2 and attempts < max_attempts:
		if current_overall < target_overall:
			# Check if we can still boost key attributes
			var can_boost_key = false
			for attr in key_attributes:
				if attributes[attr] < 100:
					can_boost_key = true
					break
			
			if can_boost_key:
				# Find a key attribute that isn't maxed
				var random_key_attr = key_attributes[randi() % key_attributes.size()]
				var boost_tries = 0
				while attributes[random_key_attr] >= 100 and boost_tries < 10:
					random_key_attr = key_attributes[randi() % key_attributes.size()]
					boost_tries += 1
				
				var boost_amount = randi_range(2, 10)
				attributes[random_key_attr] += boost_amount
				attributes[random_key_attr] = min(attributes[random_key_attr], 99)
			
			# Also boost non-key attributes more frequently and with larger amounts
			if non_key_attributes.size() > 0 and (randf() < 0.6 or not can_boost_key):
				var random_non_key_attr = non_key_attributes[randi() % non_key_attributes.size()]
				var boost_variance = randi_range(1, 8)
				attributes[random_non_key_attr] += boost_variance
				attributes[random_non_key_attr] = clamp(attributes[random_non_key_attr], 1, 99)
		else:
			if non_key_attributes.size() > 0:
				var random_non_key_attr = non_key_attributes[randi() % non_key_attributes.size()]
				var reduce_amount = randi_range(2, 10)
				attributes[random_non_key_attr] -= reduce_amount
				attributes[random_non_key_attr] = max(attributes[random_non_key_attr], 20)
			if randf() < 0.2:
				var random_key_attr = key_attributes[randi() % key_attributes.size()]
				var small_variance = randi_range(-2, 2)
				attributes[random_key_attr] += small_variance
				attributes[random_key_attr] = clamp(attributes[random_key_attr], 1, 99)
		player.attributes = attributes
		current_overall = player.calculate_overall()
		attempts += 1
	
	if abs(current_overall - target_overall) > 2:
		print("Warning: Could not reach target overall %d, achieved %d after %d attempts" % [target_overall, current_overall, attempts])

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
	var food_types = ["bbq", "island", "casserole", "mexican", "vegetarian", "noodle"]
	return food_types.pick_random()

func export_to_csv(file_path: String = "res://Assets/Rosters/roster_export.csv"):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("Error: Could not open file for writing: ", file_path)
		return
	
	# Header - Note: there's a typo in the original header where "contract_chillcontract_focus_party" should be two fields
	file.store_line("first_name,last_name,nickname,hometown,left_handed,feet,inches,pounds,years,speed_rating,blocking,positioning,aggression,reactions,durability,power,throwing,endurance,accuracy,balance,focus,shooting,toughness,confidence,agility,faceoffs,discipline,playable_positions,preferred_position,declared_pitcher,special_pitches,pitch_grooves,portrait,head,haircut,glove,shoe,body_type,skin_tone_primary,skin_tone_secondary,complexion,best_league,play_style,gender,attracted,gang,home_cooking,day_job,day_job_pay,spouses,children,elders,adults,positivity,negativity,influence,promiscuity,loyalty,love_of_the_game,professionalism,partying,potential,hustle,hardiness,combat,franchise_id,contract_type,seasons_left,salary,revenue_share,water,food,buyout,housing,tryout_games,preferred_job,job_roles,contract_focus_value,contract_focus_stability,contract_focus_flexibility,contract_focus_satiety,contract_focus_hydration,contract_focus_hometown,contract_focus_housing,contract_focus_house_type,contract_focus_gameday,contract_focus_travel,contract_focus_medical,contract_chillcontract_focus_party,contract_focus_chill,contract_win_latercontract_focus_win_now,contract_focus_win_later,contract_focus_loyalty,contract_focus_opportunity,contract_focus_community,contract_focus_development,contract_focus_safety,contract_focus_education,contract_focus_trade,contract_focus_farming,contract_focus_day_life,contract_focus_night_life,contract_focus_welfare,physical_training,technical_training,mental_training,talent_eval,talent_spotting,scouting_speed,deescalation,anti_banditry,escorting,trauma,ortho,medicine,stretching,first_aid,rehab,attraction,sponsorship,networking,masonry,carpentry,painting,sewing,carrying,acquisitions,line_cooking,home_cooking,fine_cooking,auditing,budgeting,bidding,raging,chilling,intimacy,charisma,helpfulness,longevity")
	
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
		if player.preferred_position == "P":
			player.declared_pitcher = true
		line_parts.append("TRUE" if player.declared_pitcher else "FALSE")
		line_parts.append("")  # special_pitches
		line_parts.append("")  # pitch_grooves
		
		# Appearance fields 33-41 (9 fields)
		for i in range(9):
			line_parts.append("")
		
		# Character info fields 42-45
		line_parts.append("")  # best_league
		line_parts.append(csv_escape(player.playStyle))
		line_parts.append(character.gender)
		# attracted - format as array if present
		if character.attracted and character.attracted.size() > 0:
			line_parts.append(csv_escape(str(character.attracted)))
		else:
			line_parts.append("")
		
		# Gang affiliation (field 46)
		line_parts.append(csv_escape(character.gang_affiliation if character.gang_affiliation else ""))
		
		# Home cooking and day job (fields 47-49)
		line_parts.append(character.home_cooking_style if character.home_cooking_style else "")
		line_parts.append(csv_escape(character.day_job if character.day_job else ""))
		line_parts.append(str(character.day_job_pay if character.day_job_pay else 0))
		
		# Family counts fields 50-53
		line_parts.append(str(character.spouses if character.spouses else 0))
		line_parts.append(str(character.children if character.children else 0))
		line_parts.append(str(character.elders if character.elders else 0))
		line_parts.append(str(character.adults if character.adults else 0))
		
		# Off attributes fields 54-65 (12 fields)
		var off_attr_names = ["positivity", "negativity", "influence", "promiscuity",
							  "loyalty", "love_of_the_game", "professionalism", "partying",
							  "potential", "hustle", "hardiness", "combat"]
		for attr_name in off_attr_names:
			if character.off_attributes.has(attr_name):
				line_parts.append(str(character.off_attributes[attr_name]))
			else:
				line_parts.append("")
		
		# Contract and franchise info fields 66-74 (9 fields)
		for i in range(9):
			line_parts.append("")
		
		# Additional fields: preferred_job and job_roles (fields 75-76)
		line_parts.append(character.preferred_job if character.preferred_job else "")
		# Export job_roles as a JSON string (dictionary of booleans)
		if character.job_roles:
			var job_roles_str = JSON.stringify(character.job_roles)
			line_parts.append(csv_escape(job_roles_str))
		else:
			line_parts.append("")
		
		# Contract focuses fields 77-102 (26 fields due to header typos)
		# The header has typos: "contract_chillcontract_focus_party" and "contract_win_latercontract_focus_win_now"
		# These create extra columns, so we need to match the exact column count
		var contract_focus_names = ["value", "stability", "flexibility", "satiety", "hydration",
									"hometown", "housing", "house_type", "gameday", "travel",
									"medical", "party", "chill", "win_now", "win_later",
									"loyalty", "opportunity", "community", "development", "safety",
									"education", "trade", "farming", "day_life", "night_life", "welfare"]
		# Add two empty fields for the header typos
		for attr_name in contract_focus_names:
			if character.contract_focuses.has(attr_name):
				line_parts.append(str(character.contract_focuses[attr_name]))
			else:
				line_parts.append("")
		
		# Staff skills fields 103-138 (36 fields due to home_cooking appearing twice)
		var staff_skill_names = [
			"physical_training", "technical_training", "mental_training",
			"talent_eval", "talent_spotting", "scouting_speed",
			"deescalation", "anti_banditry", "escorting",
			"trauma", "ortho", "medicine",
			"stretching", "first_aid", "rehab",
			"attraction", "sponsorship", "networking",
			"masonry", "carpentry", "painting",
			"sewing", "carrying", "acquisitions",
			"line_cooking", "home_cooking", "fine_cooking",
			"auditing", "budgeting", "bidding",
			"raging", "chilling", "intimacy",
			"charisma", "helpfulness", "longevity"
		]
		for skill_name in staff_skill_names:
			if character.staff_skills.has(skill_name):
				line_parts.append(str(character.staff_skills[skill_name]))
			else:
				line_parts.append("")
		
		# Final safety check
		var expected_fields = 138
		if line_parts.size() != expected_fields:
			print("Warning: Player %s %s has %d fields, expected %d" % [player.bio.first_name, player.bio.last_name, line_parts.size(), expected_fields])
			while line_parts.size() < expected_fields:
				line_parts.append("")
			if line_parts.size() > expected_fields:
				line_parts.resize(expected_fields)
		
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

func generate_contract_focuses(character: Character):
	var focuses = {}
	var adjusted_weights = adjust_focuses_for_character(character)
	var key_focus = weighted_random_choice(key_focus_frequency)
	focuses[key_focus] = 2.0
	# Build the pool of all other numeric focuses (everything except key focus and house_type)
	var other_focus_keys = []
	for f in adjusted_weights:
		if f != key_focus:
			other_focus_keys.append(f)

	# Draw 7 top focuses by repeatedly pulling from the adjusted weight pool
	var top_seven_focuses: Array = []
	var remaining_weights = adjusted_weights.duplicate()
	remaining_weights.erase(key_focus)   # key focus is already assigned

	for _i in range(7):
		if remaining_weights.is_empty():
			break
		var pick = weighted_random_choice(remaining_weights)
		top_seven_focuses.append(pick)
		remaining_weights.erase(pick)

	if key_focus in top_seven_focuses:
		focuses[key_focus] += randf_range(-0.5, 2.0)

	# Assign values to the top 7 focuses
	for f in top_seven_focuses:
		focuses[f] = randf_range(0.1, 4.0)

	for f in other_focus_keys:
		if f in top_seven_focuses:
			continue   # already assigned
		if randf() < 0.5:
			focuses[f] = randf_range(0.1, 2.0)
		else:
			focuses[f] = 0.0

	for f in focuses:
		if character.contract_focuses.has(f):
			character.contract_focuses[f] = focuses[f]
	
func adjust_focuses_for_character(character: Character) -> Dictionary:
	var w = other_contract_focus_frequency.duplicate()
	var age = character.player.bio.years
	var overall = character.player.calculate_overall()
	var has_family = (character.children > 0 or character.elders > 0 or character.adults > 0 or character.spouses > 0)
	var is_urban = hometowns_urban.has(character.player.bio.hometown)
	var is_rural = !is_urban
	var day_job = character.day_job

	# satiety – goes way up for big boys (heavy weight categories)
	var weight_lbs = character.player.bio.pounds
	if weight_lbs >= 265:
		w["satiety"] *= 4.0
	if weight_lbs >= 230:
		w["satiety"] *= 3.0
	elif weight_lbs >= 200:
		w["satiety"] *= 2.0

	# hydration – goes way up for players with more ambition (high overall as proxy)
	var ambition = max(character.off_attributes.love_of_the_game, character.off_attributes.hustle)
	if ambition >= 90:
		w["hydration"] *= 3.0
	elif ambition >= 55:
		w["hydration"] *= 1.2

	# housing – goes up for higher overalls and players with families
	if overall >= 95:
		w["housing"] *= 5.0
	elif overall >= 80:
		w["housing"] *= 2.0
	elif overall >= 60:
		w["housing"] *= 1.2
	if has_family:
		w["housing"] *= 1.6

	# medical – goes way up if player is higher in age
	if age >= 35:
		w["medical"] *= 2.0
	elif age >= 28:
		w["medical"] *= 1.1
	if character.off_attributes.hardiness < 25:
		w["medical"] *= 2.5
	elif character.off_attributes.hardiness < 60:
		w["medical"] *= 1.3

	# win_later – goes way down if player is higher in age
	if age >= 38:
		w["win_later"] *= 0.2
	elif age >= 32:
		w["win_later"] *= 0.5

	# community – goes up for players with families
	if has_family:
		w["community"] *= 2.0

	# safety – goes up for players with families and players from rural areas, higher for war day job
	if has_family:
		w["safety"] *= 2.0
	if is_rural:
		w["safety"] *= 1.5
	if day_job == "war" or day_job == "conscript" or day_job == "garrison trooper" or day_job == "road trooper":
		w["safety"] *= 2.5 #don't want to get raided and have to fight!

	# education – goes up for younger players and players with families
	if age <= 22:
		w["education"] *= 2.5
	elif age <= 28:
		w["education"] *= 1.5
	if has_family:
		w["education"] *= 2.0

	# trade – goes way up for players with day job in industrial, trade, transport, or finance
	var trade_jobs = ["sweatshopper", "home crafter", "wage crafter", "co-op shopkeeper", "shopkeeper",
		"promoter", "entrepreneur", "rickshaw runner", "rickshaw biker", "longshoreman",
		"horse teamster", "truck teamster", "mechanic", "warehouse owner",
		"beggar", "hawker", "repo man", "hitman", "loan shark", "accountant", "mafioso",
		"chain gang", "scrapper", "apprentice", "journeyman", "master", "artisan", "baron"]
	if day_job in trade_jobs:
		w["trade"] *= 4.0

	# farming – goes way up for players with day job in farming
	var farm_jobs = ["sharecropper", "subsistence", "farmhand", "co-op farmer", "family farmer", "veterinarian", "haciendero", "farm"]
	if day_job in farm_jobs:
		w["farming"] *= 4.0

	# day_life – goes up for players from urban areas and players with families, slightly higher for older players
	if is_urban:
		w["day_life"] *= 1.8
	if has_family:
		w["day_life"] *= 1.5
	if age >= 24:
		w["day_life"] *= 1.3

	# night_life – higher for hospitality day job, slightly higher for younger players
	var hospitality_jobs = ["sex slave", "prostitute", "cook for hire", "escort", "cart cook", "musician", "pimp"]
	if day_job in hospitality_jobs:
		w["night_life"] *= 3.0
	if age <= 28:
		w["night_life"] *= 1.4

	# welfare – goes up for players with families and older players, higher for public day job
	if has_family:
		w["welfare"] *= 2.0
	if age >= 35:
		w["welfare"] *= 1.8
	var public_jobs = ["eunuch", "janitor", "courier", "firefighter", "teacher", "professor", "aristocrat"]
	if day_job in public_jobs:
		w["welfare"] *= 2.5

	return w
	
func assign_preferred_housing_type(character: Character):
	var w = preferred_room_type_frequency.duplicate()
	var overall = character.player.calculate_overall()
	var is_urban = hometowns_urban.has(character.player.bio.hometown)
	var is_rural = !is_urban
	var day_job = character.day_job

	# tent spot goes up for players with no day job
	if day_job == "none":
		w["tent spot"] *= 3.0

	# cabin higher for players from rural places
	if is_rural:
		w["cabin"] *= 2.0

	# motel higher for players from urban places
	if is_urban:
		w["motel"] *= 2.0

	# compound and mansion are the nicest – only let players with high overalls want these
	if overall < 65:
		w["compound"] = 0.0
		w["mansion"] = 0.0
	elif overall < 90:
		w["compound"] *= 0.3
		w["mansion"] *= 0.2
	# else leave them at base (already low frequency, naturally rare)

	var housing_type = weighted_random_choice(w)
	character.contract_focuses.house_type = housing_type


func generate_job_skills(character: Character, isPlayer: bool = false):
	var possible_staff_overalls = {
		8: 10,
		9: 10,
		10: 10,
		11: 10,
		12: 10,
		13: 10,
		14: 10,
		15: 10,
		16: 9,
		17: 8,
		18: 7,
		19: 6,
		20: 5,
		21: 4,
		22: 3,
		23: 2,
		24: 1,
		25: 0.1
	}
	var staff_overall = weighted_random_choice(possible_staff_overalls) #average of attributes in relevant catagories
	if isPlayer:
		staff_overall = int(staff_overall * 0.8) #not as good at it if you're not focused on it
	var character_type = weighted_random_choice(non_player_type_frequency)
	var key_attributes: Array = []
	var ok_attributes: Array = []
	var zero_attributes: Array = []
	match character_type:
		"coach":
			key_attributes = ["physical_training", "technical_training", "mental_training"]
			ok_attributes = ["longevity", "flexibility", "decisiveness", "matchups"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
		"strength_coach":
			key_attributes = ["physical_training", "longevity"]
			ok_attributes = ["stretching"]
			zero_attributes = ["violence"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
		"skills_coach":
			key_attributes = ["technical_training"]
			ok_attributes = ["flexibility"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
		"offense_coordinator":
			key_attributes = ["mental_training", "matchups", "decisiveness"]
			ok_attributes = ["reactivity"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
		"fighting_coach":
			key_attributes = ["violence", "injury_tolerance"]
			ok_attributes = ["physical_training","technical_training","matchups","reactivity"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
		"sport_sensei":
			key_attributes = ["mental_training", "talent_eval", "talent_spotting"]
			ok_attributes = ["technical_training"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
			character.job_roles.scout = true
		"scout":
			ok_attributes = ["talent_eval", "talent_spotting", "scouting_speed"]
			character.preferred_job = "scout"
			character.job_roles.scout = true
		"surgeon":
			key_attributes = ["trauma", "ortho"]
			character.preferred_job = "surgeon"
			zero_attributes = ["injury_tolerance"]
			character.job_roles.surgeon = true
		"rehabilitator":
			key_attributes = ["ortho", "rehab"]
			zero_attributes = ["injury_tolerance","violence"]
			character.preferred_job = "medic"
			character.job_roles.medic = true
		"doctor":
			key_attributes = ["medicine"]
			ok_attributes = ["trauma","ortho"]
			zero_attributes = ["injury_tolerance"]
			character.preferred_job = "surgeon"
			character.job_roles.surgeon = true
			character.job_roles.medic = true
		"trainer":
			key_attributes = ["stretching", "rehab"]
			ok_attributes = ["first_aid"]
			character.preferred_job = "medic"
			character.job_roles.medic = true
		"paramedic":
			key_attributes = ["first_aid"]
			ok_attributes = ["stretching", "rehab"]
			character.preferred_job = "medic"
			character.job_roles.medic = true
		"military_paramedic":
			key_attributes = ["first_aid", "anti_banditry"]
			character.preferred_job = "medic"
			character.job_roles.medic = true
			character.job_roles.security = true
		"carpenter":
			key_attributes = ["carpentry"]
			character.preferred_job = "grounds"
			character.job_roles.grounds = true
		"mason":
			key_attributes = ["masonry"]
			character.preferred_job = "grounds"
			character.job_roles.grounds = true
		"painter":
			key_attributes = ["painting"]
			character.preferred_job = "grounds"
			character.job_roles.grounds = true
		"handyman":
			ok_attributes = ["carpentry", "masonry", "painting"]
			character.preferred_job = "grounds"
			character.job_roles.grounds = true
		"master_craftsman":
			key_attributes = ["carpentry", "masonry", "painting"]
			character.preferred_job = "grounds"
			character.job_roles.grounds = true
		"salesman":
			key_attributes = ["attraction"]
			character.preferred_job = "promoter"
			character.job_roles.promoter = true
		"people_pleaser":
			key_attributes = ["sponsorship", "networking", "charisma"]
			character.preferred_job = "promoter"
			character.job_roles.promoter = true
		"tailor":
			key_attributes = ["sewing"]
			character.preferred_job = "equipment"
			character.job_roles.equipment = true
		"porter":
			key_attributes = ["carrying"]
			character.preferred_job = "equipment"
			character.job_roles.equipment = true
		"logistician":
			key_attributes = ["acquisitions"]
			character.preferred_job = "equipment"
			character.job_roles.equipment = true
		"kitman":
			ok_attributes = ["sewing", "carrying", "acquisitions"]
			character.preferred_job = "equipment"
			character.job_roles.equipment = true
		"traveling_merchant":
			ok_attributes = ["carrying", "attraction"]
			character.preferred_job = "equipment"
			character.job_roles.equipment = true
			character.job_roles.promoter = true
		"big_family_cook":
			key_attributes = ["line_cooking", "home_cooking"]
			character.preferred_job = "cook"
			character.job_roles.cook = true
		"haute_chef":
			key_attributes = ["fine_cooking", "line_cooking"]
			character.preferred_job = "cook"
			character.job_roles.cook = true
		"grill_master":
			key_attributes = ["home_cooking", "fine_cooking"]
			character.preferred_job = "cook"
			character.job_roles.cook = true
		"spreadsheet_wizard":
			key_attributes = ["auditing", "budgeting"]
			character.preferred_job = "accountant"
			character.job_roles.accountant = true
		"business_sleuth":
			key_attributes = ["auditing", "charisma"]
			character.preferred_job = "accountant"
			character.job_roles.accountant = true
		"groupie":
			key_attributes = ["raging", "intimacy"]
			ok_attributes = ["chilling"]
			character.preferred_job = "entourage"
			character.job_roles.entourage = true
		"prostitute":
			key_attributes = ["intimacy"]
			ok_attributes = ["raging", "chilling"]
			character.preferred_job = "entourage"
			character.job_roles.entourage = true
		"homie":
			key_attributes = ["chilling"]
			ok_attributes = ["raging"]
			zero_attributes = ["intimacy"]
			character.preferred_job = "entourage"
			character.job_roles.entourage = true
		"party_planner":
			key_attributes = ["raging", "chilling"]
			zero_attributes = ["intimacy"]
			character.preferred_job = "entourage"
			character.job_roles.entourage = true
		"stripper":
			key_attributes = ["attraction"]
			ok_attributes = ["intimacy", "raging"]
			character.preferred_job = "entourage"
			character.job_roles.entourage = true
			character.job_roles.promoter = true
		"bodyguard":
			key_attributes = ["escorting", "anti_banditry"]
			character.preferred_job = "security"
			character.job_roles.security = true
		"escort":
			key_attributes = ["escorting", "intimacy"]
			character.preferred_job = "security"
			character.job_roles.security = true
			character.job_roles.entourage = true
		"usher":
			key_attributes = ["deescalation"]
			character.preferred_job = "security"
			character.job_roles.security = true
		"minder":
			key_attributes = ["deescalation", "escorting"]
			character.preferred_job = "security"
			character.job_roles.security = true
		"gun_for_hire":
			key_attributes = ["anti_banditry", "raging"]
			character.preferred_job = "security"
			character.job_roles.security = true
			character.job_roles.entourage = true
		"contract_lawyer":
			key_attributes = ["bidding", "sponsorship"]
			character.preferred_job = "accountant"
			character.job_roles.accountant = true
			character.job_roles.promoter = true
		"friendly_face":
			key_attributes = ["deescalation", "chilling", "charisma"]
			character.preferred_job = "security"
			character.job_roles.security = true
			character.job_roles.entourage = true
		"gym_bro":
			key_attributes = ["physical_training", "stretching", "carrying"]
			character.preferred_job = "coach"
			character.job_roles.coach = true
			character.job_roles.medic = true
			character.job_roles.equipment = true
		_:
			pass
	if character.player.bio.years < 26 and character_type not in ["doctor", "surgeon", "trainer"]:
		zero_attributes.append("ortho")
	# ---------------------------------------------------------------------------
	# Assign values to every staff_skill on the character
	# ---------------------------------------------------------------------------
	var all_staff_attributes: Array = [
		"physical_training", "technical_training", "mental_training",
		"eccentricity", "decisiveness", "flexibility", "reactivity",
		"matchups", "violence", "injury_tolerance",
		"talent_eval", "talent_spotting", "scouting_speed",
		"deescalation", "anti_banditry", "escorting",
		"trauma", "ortho", "medicine",
		"stretching", "first_aid", "rehab",
		"attraction", "sponsorship", "networking",
		"masonry", "carpentry", "painting",
		"sewing", "carrying", "acquisitions",
		"line_cooking", "home_cooking", "fine_cooking",
		"auditing", "budgeting", "bidding",
		"raging", "chilling", "intimacy",
		"charisma", "helpfulness", "longevity"
	]
	var all_off_attributes: Array = [
		"positivity","negativity","influence","promiscuity",
		"loyalty","love_of_the_game","professionalism","partying",
		"potential","hustle","hardiness","combat"]

	for attribute in all_staff_attributes:
		var value: int
		if attribute in key_attributes:
			value = min(randi_range(staff_overall - 4, staff_overall + 4), 20)
			character.staff_skills[attribute] = value
		elif attribute in zero_attributes:
			character.staff_skills[attribute] = 0
		elif attribute in ok_attributes:
			var max = max(staff_overall - 1, staff_overall * 0.8)
			value = min(randi_range(staff_overall - 5, max), 20)
			character.staff_skills[attribute] = value
		else:
			var rand = randf()
			if rand < 0.2:
				value = randi_range(0, int(staff_overall * 0.8))
			elif rand < 0.5:
				value = randi_range(0, int(staff_overall * 0.5))
			else:
				value = randi_range(0, int(staff_overall * 0.3))
			character.staff_skills[attribute] = value
			
	for attribute in all_off_attributes:
		var value
		if attribute == "combat":
			if character_type in ["gun_for_hire", "bodyguard", "military_paramedic"]:
				value = randi_range(25,99)
			else:
				# Default combat value for all other characters
				value = randi_range(1,50)
		elif attribute == "potential":
			var real_max_possible = 115 - character.player.bio.years
			var max_ovr = max(character.player.calculate_overall(),real_max_possible)
			var min_ovr = max(character.player.calculate_overall(),min_overall)
			value = randi_range(min_ovr,max_ovr)
		else:
			if randf() < 0.5:
				value = randi_range(0,99)
			else:
				value = randi_range(25,75)
				if randf() < 0.5:
					value = int((value + 50) / 2)
		character.off_attributes[attribute] = value
	
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
		
func generate_family_members(character: Character):
	var num_spouses = character.spouses
	var age = character.player.bio.years
	var children: int = 0
	var adults: int = 0
	var elders: int = 0
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
			elif (roommate_age <= age - 14 and roommate_age <= 23) or roommate_age < 16: #that character's child or literally a child
				children += 1 
			else:
				adults += 1
	character.children = children
	character.elders = elders
	character.adults = adults
	character.family = character.spouses + character.children + character.adults + character.elders

func generate_orientation(gender: String):
	var attracted = []
	var rand = randf()
	if gender == "i":
		if rand < 0.2:
			attracted = ["i"]
		elif rand < 0.29:
			attracted = []
		elif rand < 0.59:
			attracted = ["m"]
		elif rand < 0.89:
			attracted = ["f"]
		elif rand < 0.98:
			attracted = ["m","f","i"]
		else:
			attracted = ["m","f"]
	elif gender == "f":
		if rand < 0.5:
			attracted = ["m"]
		elif rand < 0.7:
			attracted = ["m", "i"]
		elif rand < 0.86:
			attracted = ["f","i","m"]
		elif rand < 0.91:
			attracted = ["f","i"]
		elif rand < 0.93:
			attracted = ["f"]
		elif rand < 0.97:
			attracted = []
		else:
			attracted = ["f","m"]
	elif gender == "m":
		if rand < 0.5:
			attracted = ["f"]
		elif rand < 0.7:
			attracted = ["f", "i"]
		elif rand < 0.86:
			attracted = ["f","i","m"]
		elif rand < 0.91:
			attracted = ["m","i"]
		elif rand < 0.93:
			attracted = ["m"]
		elif rand < 0.97:
			attracted = []
		else:
			attracted = ["f","m"]
	
	return attracted

func generate_characters(non_players: int):
	if characters_players.size() <= 0:
		generate_players(characters_players.size() if characters_players.size() > 0 else 2000, false)

	# Generate the staff pool with compressed overalls and general-population demographics
	characters_staff.clear()
	generate_players(non_players, true)

	for character in characters:
		var day_job_info = get_day_job()
		character.day_job = day_job_info["job"]
		character.day_job_pay = day_job_info["pay"]
		character.spouses = determine_number_of_spouses(character.player.bio.years)
		generate_family_members(character)
		character.home_cooking_style = get_favorite_food()
		var is_footballer = characters_players.has(character)
		generate_job_skills(character, is_footballer)
		generate_contract_focuses(character)
		assign_preferred_housing_type(character)
		
		character.attracted = generate_orientation(character.gender)
		
		# Assign gang affiliation based on gang_rate
		if randf() < gang_rate:
			character.gang_affiliation = gangs[randi() % gangs.size()]
		else:
			character.gang_affiliation = ""

func generate_special_pitches() -> Array[String]:
	var pitches: Array[String] = []
	for i in range(0, 3):
		var random_pitch = weighted_random_choice(pitch_type_frequency)
		if random_pitch in pitches:
			pitches.append("none")
		else:
			pitches.append(random_pitch)
	return pitches

func get_unsigned_players() -> Array[Character]:
	var unsigned: Array[Character] = []
	for character in characters_players:
		if not CareerFranchise.contracts.has(character.id):
			unsigned.append(character)
	return unsigned

func get_unsigned_staff() -> Array[Character]:
	var unsigned: Array[Character] = []
	for character in characters_staff:
		if not CareerFranchise.contracts.has(character.id):
			unsigned.append(character)
	return unsigned
