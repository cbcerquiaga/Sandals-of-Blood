extends Node

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

#players are more likely to be bigger, healthier people
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

var name_frequency_first:= {
	"common": 42,
	"apocalypse": 10,
	"afro": 15,
	"spanish": 10,
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
	"native": 0.2,
	"apocalypse": 15,
	"spanish": 11.5,
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
	"slavic": 0.6,
	"nordic": 0.6,
	"indian": 0.7,
	"japanese": 0.8,
	"chinese": 0.5,
	"korean": 0.5,
	"wasp": 0.2,
	"africa": 0.9,
	"row": 1,
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

# Physical attribute modifiers (updated per request)
const HEIGHT_MODIFIERS = {
	"agility": -0.8,      # Taller = less agile
	"balance": -0.6,      # Taller = less balanced
	"throwing": 0.7,      # Taller = better throwing
	"faceoffs": 0.5,      # Taller = better at faceoffs
	"blocking": 0.3       # Taller = better blocking (removed positioning)
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
var first_names_common_m = [] #
var first_names_apocalypse_m = []
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
var first_names_arab_m = []
var first_names_japanese_m = []
var first_names_korean_m = []
var first_names_pacific_m = []#

var first_names_common_f = []
var first_names_apocalypse_f = []
var first_names_wasp_f = []
var first_names_afro_f = []
var first_names_africa_f = []
var first_names_spanish_f = []
var first_names_french_f = []
var first_names_italian_f = []
var first_names_slavic_f = []
var first_names_nordic_f = []
var first_names_chinese_f = []
var first_names_indian_f = []
var first_names_arab_f = []
var first_names_japanese_f = []
var first_names_korean_f = []
var first_names_pacific_f = []#

var last_names_common = []#
var last_names_native = []
var last_names_apocalypse = []
var last_names_wasp = []
var last_names_africa = []#
var last_names_spanish = []#
var last_names_french = []
var last_names_italian = []
var last_names_slavic_m = []
var last_names_slavic_f = []
var last_names_nordic_m = []
var last_names_nordic_f = []
var last_names_chinese = []
var last_names_indian = []#
var last_names_japanese = []
var last_names_korean = []
var last_names_arab = []
var last_names_pacific = []

var hometowns_urban = []
var hometowns_rural = []
var town_weight_chance = 0.54 #54% urbanization rate

func _ready():
	randomize()
	initialize_name_lists()

func load_csv_to_array(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	var array: Array = []
	
	if file:
		var content = file.get_as_text()
		file.close()
		
		# Check if it's RTF format (starts with {)
		if content.begins_with("{"):
			# Extract the content after the first } (RTF header)
			var end_brace_pos = content.find("}")
			if end_brace_pos != -1:
				content = content.substr(end_brace_pos + 1)
		
		# Split by commas and clean up
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
	last_names_native = load_csv_to_array("res://Assets/Gen Names/last_native.txt")
	last_names_apocalypse = load_csv_to_array("res://Assets/Gen Names/last_apocalypse.txt")
	last_names_wasp = load_csv_to_array("res://Assets/Gen Names/last_wasp.txt")
	last_names_africa = load_csv_to_array("res://Assets/Gen Names/last_africa.txt")
	last_names_spanish = load_csv_to_array("res://Assets/Gen Names/last_spanish.txt")
	last_names_french = load_csv_to_array("res://Assets/Gen Names/last_french.txt")
	last_names_italian = load_csv_to_array("res://Assets/Gen Names/last_italian.txt")
	last_names_slavic_m = load_csv_to_array("res://Assets/Gen Names/last_slavic_m.txt")
	last_names_slavic_f = load_csv_to_array("res://Assets/Gen Names/last_slavic_f.txt")
	last_names_nordic_m = load_csv_to_array("res://Assets/Gen Names/last_nordic_m.txt")
	last_names_nordic_f = load_csv_to_array("res://Assets/Gen Names/last_nordic_f.txt")
	last_names_chinese = load_csv_to_array("res://Assets/Gen Names/last_chinese.txt")
	last_names_indian = load_csv_to_array("res://Assets/Gen Names/last_indian.txt")
	last_names_japanese = load_csv_to_array("res://Assets/Gen Names/last_japanese.txt")
	last_names_korean = load_csv_to_array("res://Assets/Gen Names/last_korean.txt")
	last_names_pacific = load_csv_to_array("res://Assets/Gen Names/last_pacific.txt")
	hometowns_urban = load_csv_to_array("res://Assets/Gen Names/hometowns_urban.txt")
	hometowns_rural = load_csv_to_array("res://Assets/Gen Names/hometowns_rural.txt")

func generate_players(num: int):
	characters.clear()
	
	for i in range(num):
		var new_player = Player.new()
		
		# Generate basic info
		var gender = determine_gender(true)
		new_player.bio.leftHanded = randf() < left_hand_frequency
		new_player.bio.years = randi_range(min_age, max_age)
		
		# Generate name
		var names = generate_random_names(gender)
		new_player.bio.first_name = names[0]
		new_player.bio.last_name = names[1]
		var rand = randf()
		names = mix_match_names(names, gender)
		#TODO: if rand is less than corresponding last name category for the player, choose first name from the corresponding first name array
		# Generate height and weight
		var physical = generate_physical_attributes(gender)
		new_player.bio.feet = physical["feet"]
		new_player.bio.inches = physical["inches"]
		new_player.bio.pounds = physical["weight"]
		new_player.bio.hometown = generate_hometown()
		
		# Generate primary position
		var primary_position = weighted_random_choice(position_frequency)
		new_player.preferred_position = primary_position
		new_player.field_position = primary_position
		
		# Generate playable positions
		new_player.playable_positions = generate_playable_positions(primary_position)
		
		# Generate attributes based on physical traits and position
		generate_attributes(new_player, gender, physical["height_inches"], physical["weight"], physical["category"])
		
		# Determine player type based on highest overall
		new_player.calculate_player_type()
		
		characters.append(new_player)

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
	# Generate height using normal distribution
	var height_data = height_distribution["male"] if gender == "m" else height_distribution["female"]
	var height_inches: int
	
	# Generate height with normal distribution (bell curve)
	var attempts = 0
	while attempts < 100:
		# Box-Muller transform for normal distribution
		var u1 = randf()
		var u2 = randf()
		var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
		
		height_inches = int(height_data["avg"] + z0 * height_data["std_dev"])
		
		# Ensure within bounds
		if height_inches >= height_data["min"] and height_inches <= height_data["max"]:
			break
		attempts += 1
	
	# Fallback to uniform distribution if normal fails
	if attempts >= 100:
		height_inches = randi_range(height_data["min"], height_data["max"])
	
	# Calculate feet and inches
	var feet = height_inches / 12
	var inches = height_inches % 12
	
	# Generate weight category (adjusted for players)
	var weight_category = generate_weight_category_for_player()
	var category_data = weight_categories[weight_category]
	
	# Calculate weight within category range, adjusted for height
	var height_meters = height_inches * 0.0254
	
	# Calculate theoretical BMI range for height
	var min_bmi_weight = category_data["bmi_range"]["min"] * height_meters * height_meters * 2.20462
	var max_bmi_weight = category_data["bmi_range"]["max"] * height_meters * height_meters * 2.20462
	
	# Clamp to category's weight range and overall limits
	var min_weight = max(category_data["weight_range"]["min"], min_bmi_weight, 90)
	var max_weight = min(category_data["weight_range"]["max"], max_bmi_weight, 350)
	
	# Ensure min <= max
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
	# Calculate adjusted frequencies for players
	var adjusted_frequencies = {}
	var total_weight = 0.0
	
	for category in weight_categories:
		var base_freq = weight_categories[category]["frequency"]
		var player_adjustment = player_weight_frequency_adjustment.get(category, 1.0)
		var adjusted_freq = base_freq * player_adjustment
		adjusted_frequencies[category] = adjusted_freq
		total_weight += adjusted_freq
	
	# Weighted random selection
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	
	for category in adjusted_frequencies:
		cumulative += adjusted_frequencies[category]
		if rand_value <= cumulative:
			return category
	
	return "old_world"  # Default fallback

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
	var first_name_category = weighted_random_choice(name_frequency_last)
	var first_name = ""
	var gender = passed_gender
	if passed_gender == "i": #intersex characters will pick one 50/50
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
		"row":
			var array = first_names_pacific_m if gender == "m" else first_names_pacific_f
			first_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
	
	var last_name_category = weighted_random_choice(name_frequency_last)
	var last_name = ""
	
	match last_name_category:
		"common":
			last_name = last_names_common[randi() % last_names_common.size()] if last_names_common.size() > 0 else "Unknown"
		"italian":
			last_name = last_names_italian[randi() % last_names_italian.size()] if last_names_italian.size() > 0 else "Unknown"
		"native":
			last_name = last_names_native[randi() % last_names_native.size()] if last_names_native.size() > 0 else "Unknown"
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
			var array = last_names_nordic_m if gender == "m" else last_names_nordic_f
			last_name = array[randi() % array.size()] if array.size() > 0 else "Unknown"
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
		"row":
			last_name = last_names_pacific[randi() % last_names_pacific.size()] if last_names_pacific.size() > 0 else "Unknown"
	
	return [first_name, last_name, last_name_category]

func mix_match_names(names: Array, gender: String) -> Array:
	# names[0] = first name
	# names[1] = last name
	# names[2] = last name category
	
	var last_name_category = names[2]
	
	# Check if we should try to match last name category with first name
	# Map last name categories to first name categories (some don't have exact matches)
	var category_map = {
		"common": "common",
		"italian": "italian",
		"native": "common",
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
		
		# Check if this category has a mix_fix_chance
		if mix_fix_chance.has(first_name_category):
			var chance = mix_fix_chance[first_name_category]
			
			if randf() < chance:
				# Replace first name with matching category
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
	
	# Add secondary positions with bias toward similar positions
	for i in range(num_positions - 1):
		if all_positions.size() == 0:
			break
		var weights = {}
		for pos in all_positions:
			var weight = 1.0
			# Similar positions get higher weight
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
		"speed": 110.0,  # Will be recalculated
		"sprint_speed": 140.0,  # Will be recalculated
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
	scale_attributes_to_overall_with_variance(player, attributes, style)
	for key in attributes.keys():
		if key != "speed" and key != "sprint_speed":  # These are derived
			attributes[key] = clamp(int(attributes[key]), 1, 100)
	attributes.speed = attributes.speedRating + 35
	attributes.sprint_speed = (attributes.speedRating - 5) * 2
	player.attributes = attributes

func apply_physical_modifiers(attributes: Dictionary, height_inches: int, weight_category: String):
	# Calculate height factor (0-1, where 0 is shortest, 1 is tallest for average gender)
	var height_data = height_distribution["male"]  # Use male as reference
	var height_factor = float(height_inches - height_data["min"]) / float(height_data["max"] - height_data["min"])
	height_factor = clamp(height_factor, 0.0, 1.0)
	
	# Apply height modifiers
	for modifier in HEIGHT_MODIFIERS:
		if attributes.has(modifier):
			var adjustment = HEIGHT_MODIFIERS[modifier] * (height_factor * 20)  # ±20 max
			attributes[modifier] += adjustment
	
	# Apply weight category modifiers
	if WEIGHT_CATEGORY_MODIFIERS.has(weight_category):
		var category_modifiers = WEIGHT_CATEGORY_MODIFIERS[weight_category]
		for modifier in category_modifiers:
			if attributes.has(modifier):
				attributes[modifier] += category_modifiers[modifier]

func apply_position_base_adjustments(attributes: Dictionary, position: String):
	# Apply larger variance in position adjustments
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
		"P": #TODO: use weights
			var style_choices = ["Ace", "Workhorse", "Hatchet Man", "Track Hog"]
			return style_choices[randi() % style_choices.size()]
		"K": #TODO: use weights
			var keeper_choices = ["Acrobatic", "Crouching", "Kneeling", "Standing"]
			return keeper_choices[randi() % keeper_choices.size()]
		"LF", "RF":
			var scores = {}
			scores["Goal Scorer"] = (attributes.shooting + attributes.accuracy) / 2.0
			scores["Anti-Keeper"] = (attributes.power + attributes.speedRating) / 2.0
			scores["Support Forward"] = (attributes.positioning + attributes.reactions) / 2.0
			scores["Skull Cracker"] = (attributes.toughness + attributes.aggression) / 2.0
			
			var best_style = "Goal Scorer"
			var best_score = 0.0
			for style in scores:
				if scores[style] > best_score:
					best_score = scores[style]
					best_style = style
			return best_style
		
		"LG", "RG":
			var scores = {}
			scores["Ball Hound"] = (attributes.reactions + attributes.blocking) / 2.0
			scores["Defender"] = (attributes.positioning + attributes.speedRating) / 2.0
			scores["Bully"] = (attributes.power + attributes.toughness) / 2.0
			
			var best_style = "Ball Hound"
			var best_score = 0.0
			for style in scores:
				if scores[style] > best_score:
					best_score = scores[style]
					best_style = style
			
			return best_style
	
	return "Standing"  # Default fallback

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

func scale_attributes_to_overall_with_variance(player: Player, attributes: Dictionary, style: String):
	player.attributes = attributes #set attributes temporarily to calculate current overall
	var current_overall = player.calculate_overall()
	var target_overall = randi_range(min_overall, max_overall) #TODO: factor in age, potential, hustle
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
		# Pitcher styles
		"Ace":
			return ["power", "throwing", "focus", "accuracy", "confidence"]
		"Workhorse":
			return ["endurance", "confidence", "accuracy", "power", "throwing", "focus"]
		"Hatchet Man":
			return ["toughness", "shooting", "power", "speedRating", "durability", "balance"]
		"Track Hog":
			return ["reactions", "faceoffs", "accuracy", "speedRating"]
		
		# Keeper styles
		"Acrobatic":
			return ["agility", "reactions", "speedRating"]
		"Crouching":
			return ["endurance", "balance", "durability"]
		"Kneeling":
			return ["focus", "confidence", "accuracy"]
		"Standing":
			return ["power", "blocking", "aggression"]
		
		# Forward styles
		"Goal Scorer":
			return ["shooting", "accuracy", "speedRating"]
		"Anti-Keeper":
			return ["power", "speedRating", "endurance"]
		"Support Forward":
			return ["positioning", "power", "accuracy"]
		"Skull Cracker":
			return ["toughness", "aggression", "power"]
		
		# Guard styles
		"Ball Hound":
			return ["reactions", "shooting", "speedRating"]
		"Defender":
			return ["positioning", "speedRating", "endurance"]
		"Bully":
			return ["power", "toughness", "aggression"]
		
		_:
			# Default fallback - return a basic set of attributes
			return ["speedRating", "power", "shooting", "accuracy"]

# Public API functions
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
	info += "Key Attributes:\n"
	info += "  Speed: %d, Power: %d, Shooting: %d, Accuracy: %d\n" % [
		player.attributes.speedRating, player.attributes.power,
		player.attributes.shooting, player.attributes.accuracy
	]
	info += "  Toughness: %d, Endurance: %d, Reactions: %d, Balance: %d\n" % [
		player.attributes.toughness, player.attributes.endurance,
		player.attributes.reactions, player.attributes.balance
	]
	info += "  Throwing: %d, Faceoffs: %d, Agility: %d\n" % [
		player.attributes.throwing, player.attributes.faceoffs,
		player.attributes.agility
	]
	return info

func clear_players():
	characters.clear()
