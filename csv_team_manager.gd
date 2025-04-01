class_name csv_team_manager
extends Node

const BASE_SKILLS = ["HP", "strength"]
const BASE_STATS = ["games_played"]
const ROLE_SKILLS = {
	"Batter": ["contact", "hitting_power", "speed", "agility", "attack", "shooting", "blocking", "toughness"],
	"Goalie": ["aggression", "positioning", "speed", "agility", "attack", "shooting", "blocking", "toughness"],
	"Forward": ["aggression", "positioning", "speed", "agility", "attack", "shooting", "blocking", "toughness"],
	"Pitcher": ["velocity", "left_curve", "right_curve", "accuracy", "consistency", "longevity", "teamwork"],
	"Catcher": ["speed", "agility", "catching", "endurance", "passing", "blocking", "focus", "tackling"],
	"Flanker": ["speed", "agility", "catching", "tackling", "man_to_man", "zone", "endurance", "passing"],
	"Safety": ["speed", "agility", "catching", "tackling", "man_to_man", "zone", "endurance", "passing"]
}

const ROLE_STATS = {
	"Batter": ["attempts", "hits", "batting_average", "goals_scored", "shutouts", "KOs"],
	"Goalie": ["balls_in_place", "goals_against", "goals_against_average", "goals_scored", "shutouts", "KOs"],
	"Forward": ["goals_for", "goals_against", "plus_minus_rating", "goals_scored", "shutouts", "KOs"],
	"Pitcher": ["pitches_thrown", "pitches_caught", "catch_percentage", "pitches_hit", "hit_percentage"],
	"Catcher": ["balls_faced", "catches", "drops", "catch_percentage", "tackles", "touchdowns_scored", "extra_points_scored"],
	"Flanker": ["touchdowns_for", "touchdowns_against", "plus_minus_rating", "passes_blocked", "tackles", "touchdowns_scored", "extra_points_scored"],
	"Safety": ["attacks_faced", "touchdowns_against", "stop_rate", "passes_blocked", "tackles", "touchdowns_scored", "extra_points_scored"]
}

static func save_team_to_csv(team_data: Array, file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: ", file_path)
		return false
	
	# Build comprehensive header
	var header = [
		"first_name", "last_name", "nickname", 
		"body_sprite", "head_sprite", "role", 
		"age", "stamina", "handedness", "xp"
	]
	
	# Add all possible skills and stats (removing duplicates)
	header += BASE_SKILLS
	header += BASE_STATS
	
	for role in ROLE_SKILLS.keys():
		for skill in ROLE_SKILLS[role]:
			if not skill in header:
				header.append(skill)
	
	for role in ROLE_STATS.keys():
		for stat in ROLE_STATS[role]:
			if not stat in header:
				header.append(stat)
	
	file.store_csv_line(header)
	
	# Write player data
	for player in team_data:
		var line = []
		
		# Basic info
		line.append(player.get("first_name", ""))
		line.append(player.get("last_name", ""))
		line.append(player.get("nickname", ""))
		line.append(player.get("body_sprite", ""))
		line.append(player.get("head_sprite", ""))
		line.append(player.get("role", ""))
		line.append(str(player.get("age", 0)))
		line.append(str(player.get("stamina", 0)))
		line.append(player.get("handedness", "right"))
		line.append(str(player.get("xp", 0)))
		
		# Base skills
		for skill in BASE_SKILLS:
			line.append(str(player.get("skills", {}).get(skill, 0)))
		
		# Base stats
		for stat in BASE_STATS:
			line.append(str(player.get("stats", {}).get(stat, 0)))
		
		# Role-specific skills and stats
		var all_columns = BASE_SKILLS + BASE_STATS + ROLE_SKILLS.values().reduce(func(a, b): return a + b, []) + ROLE_STATS.values().reduce(func(a, b): return a + b, [])
		for column in header.slice(header.find(BASE_SKILLS[0])) if header.find(BASE_SKILLS[0]) != -1 else []:
			if column in BASE_SKILLS or column in BASE_STATS:
				continue  # Already handled
			
			# Check if this column applies to the player
			var value = 0
			if column in ROLE_SKILLS.get(player["role"], []):
				value = player.get("skills", {}).get(column, 0)
			elif column in ROLE_STATS.get(player["role"], []):
				value = player.get("stats", {}).get(column, 0)
			
			line.append(str(value))
		
		file.store_csv_line(line)
	
	file.close()
	return true

static func load_team_from_csv(file_path: String) -> Array:
	var team_data = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file for reading: ", file_path)
		return []
	
	# Read header
	var header = file.get_csv_line()
	if header.size() == 0:
		return []
	
	# Process each player
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < header.size():
			continue
		
		var player = {
			"first_name": line[header.find("first_name")],
			"last_name": line[header.find("last_name")],
			"nickname": line[header.find("nickname")],
			"body_sprite": line[header.find("body_sprite")],
			"head_sprite": line[header.find("head_sprite")],
			"role": line[header.find("role")],
			"age": line[header.find("age")].to_int(),
			"stamina": line[header.find("stamina")].to_float(),
			"handedness": line[header.find("handedness")],
			"xp": line[header.find("xp")].to_int(),
			"skills": {},
			"stats": {}
		}
		
		# Load base skills
		for skill in BASE_SKILLS:
			if header.has(skill):
				player["skills"][skill] = line[header.find(skill)].to_float()
		
		# Load base stats
		for stat in BASE_STATS:
			if header.has(stat):
				player["stats"][stat] = line[header.find(stat)].to_int()
		
		# Load role-specific skills
		var role_skills = ROLE_SKILLS.get(player["role"], [])
		for skill in role_skills:
			if header.has(skill):
				player["skills"][skill] = line[header.find(skill)].to_float()
		
		# Load role-specific stats
		var role_stats = ROLE_STATS.get(player["role"], [])
		for stat in role_stats:
			if header.has(stat):
				player["stats"][stat] = line[header.find(stat)].to_float() if stat.contains("percentage") or stat.contains("rate") or stat.contains("average") else line[header.find(stat)].to_int()
		
		team_data.append(player)
	
	file.close()
	return team_data

static func create_sample_player(role: String) -> Dictionary:
	var skills = {}
	var stats = {
		"games_played": 0
	}
	
	# Base skills
	for skill in BASE_SKILLS:
		skills[skill] = randf_range(50, 100)
	
	# Role-specific skills
	for skill in ROLE_SKILLS.get(role, []):
		skills[skill] = randf_range(50, 100)
	
	# Role-specific stats
	for stat in ROLE_STATS.get(role, []):
		if stat.contains("percentage") or stat.contains("rate") or stat.contains("average"):
			stats[stat] = 0.0
		else:
			stats[stat] = 0
	
	return {
		"first_name": "First",
		"last_name": "Last",
		"nickname": "Nick",
		"body_sprite": "res://sprites/body.png",
		"head_sprite": "res://sprites/head.png",
		"role": role,
		"age": randi() % 10 + 18,
		"stamina": randf_range(50, 100),
		"handedness": "left" if randf() > 0.5 else "right",
		"xp": randi() % 1000,
		"skills": skills,
		"stats": stats
	}

static func update_player_stats(player: Dictionary, new_stats: Dictionary) -> Dictionary:
	# Update base stats
	for stat in BASE_STATS:
		if new_stats.has(stat):
			player["stats"][stat] = new_stats[stat]
	
	# Update role-specific stats
	var role_stats = ROLE_STATS.get(player["role"], [])
	for stat in role_stats:
		if new_stats.has(stat):
			player["stats"][stat] = new_stats[stat]
	
	# Calculate derived stats
	_calculate_derived_stats(player)
	return player

static func _calculate_derived_stats(player: Dictionary):
	match player["role"]:
		"Batter":
			if player["stats"].has("attempts") and player["stats"]["attempts"] > 0:
				player["stats"]["batting_average"] = float(player["stats"]["hits"]) / player["stats"]["attempts"]
		"Goalie":
			if player["stats"].has("games_played") and player["stats"]["games_played"] > 0:
				player["stats"]["goals_against_average"] = float(player["stats"]["goals_against"]) / player["stats"]["games_played"]
		"Pitcher":
			if player["stats"].has("pitches_thrown") and player["stats"]["pitches_thrown"] > 0:
				player["stats"]["catch_percentage"] = float(player["stats"]["pitches_caught"]) / player["stats"]["pitches_thrown"]
				player["stats"]["hit_percentage"] = float(player["stats"]["pitches_hit"]) / player["stats"]["pitches_thrown"]
		"Catcher":
			if player["stats"].has("balls_faced") and player["stats"]["balls_faced"] > 0:
				player["stats"]["catch_percentage"] = float(player["stats"]["catches"]) / player["stats"]["balls_faced"]
		"Forward", "Flanker", "Safety":
			player["stats"]["plus_minus_rating"] = player["stats"].get("goals_for", 0) - player["stats"].get("goals_against", 0)
		"Safety":
			if player["stats"].has("attacks_faced") and player["stats"]["attacks_faced"] > 0:
				player["stats"]["stop_rate"] = 1.0 - (float(player["stats"]["touchdowns_against"]) / player["stats"]["attacks_faced"])
