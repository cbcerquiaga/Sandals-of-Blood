# gear_importer.gd
extends Node
class_name GearImporter

@export var csv_file_path: String = "res://Assets/Equipment/debug_gear.csv"

var imported_gear: Array[Equipment] = []

func _ready():
	import_gear_from_csv(csv_file_path)

func import_gear_from_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open gear CSV file: " + path)
		return
	
	var header = file.get_csv_line() # Read header row
	var column_indices = {} # Store column indices for faster lookup
	for i in range(header.size()):
		column_indices[header[i]] = i
	
	var line_number = 1
	while file.get_position() < file.get_length():
		var row = file.get_csv_line()
		line_number += 1
		
		if row.size() == 0 or (row.size() == 1 and row[0] == ""):
			continue
			
		if row.size() != header.size():
			push_error("Row " + str(line_number) + " has incorrect number of columns. Expected: " + str(header.size()) + ", Got: " + str(row.size()))
			continue
			
		var gear = Equipment.new()
		set_gear_properties(gear, row, column_indices)
		
		# Handle team ownership
		var team_abbreviation = get_csv_value(row, column_indices, "team_abbreviation", "")
		if team_abbreviation != "":
			gear.owned_by_team = true
			# Try to find and assign the team
			if GameWorld and GameWorld.leagues:
				var team_found = false
				for league in GameWorld.leagues:
					for team in league.teams:
						if team.team_abbreviation == team_abbreviation:
							team_found = true
							break
					if team_found:
						break
				if not team_found:
					push_warning("Team with abbreviation '" + team_abbreviation + "' not found in row " + str(line_number))
		var owner_id = get_csv_value(row, column_indices, "owner_player_id", "")
		if owner_id != "":
			gear.owned_by_team = false
			assign_player_owner(gear, owner_id)
		
		imported_gear.append(gear)
		print("Imported gear: " + gear.item_name + " (" + gear.get_type() + ")")
	
	file.close()
	print("Gear import complete. Loaded " + str(imported_gear.size()) + " items")

func set_gear_properties(gear: Equipment, row: PackedStringArray, column_indices: Dictionary) -> void:
	gear.item_name = get_csv_value(row, column_indices, "item_name", "Unknown Gear")
	gear.description = get_csv_value(row, column_indices, "description", "")
	gear.img_path = get_csv_value(row, column_indices, "img_path", "")
	
	# Parse hue from hex string
	var hue_hex = get_csv_value(row, column_indices, "hue", "#ffffff")
	gear.hue = Color(hue_hex)
	
	# Parse gear type
	var gear_type_str = get_csv_value(row, column_indices, "gear_type", "ACCESSORY").to_upper()
	match gear_type_str:
		"LEG":
			gear.gear_type = Equipment.GearType.LEG
		"ELBOW":
			gear.gear_type = Equipment.GearType.ELBOW
		"GLOVE":
			gear.gear_type = Equipment.GearType.GLOVE
		"R_GLOVE":
			gear.gear_type = Equipment.GearType.R_GLOVE
		"L_GLOVE":
			gear.gear_type = Equipment.GearType.L_GLOVE
		"SHOE":
			gear.gear_type = Equipment.GearType.SHOE
		_:
			gear.gear_type = Equipment.GearType.ACCESSORY
	
	gear.buffs = {}
	
	var bonus_types = [
		"ALL", "RAIN", "WIND", "HOT", "COLD", "HOME", "AWAY", 
		"INJURED", "MISMATCHED", "MISMATCHING", "CLUTCH", "COMEBACK"
	]
	
	for bonus_type in bonus_types:
		var bonus_column = "bonus_" + bonus_type.to_lower()
		var bonus_string = get_csv_value(row, column_indices, bonus_column, "")
		
		if bonus_string != "":
			var bonus_data = parse_bonus_string(bonus_string)
			if bonus_data:
				gear.buffs[bonus_type] = bonus_data

func parse_bonus_string(bonus_string: String) -> Dictionary:
	var result = {
		"attributes": [],
		"values": []
	}
	
	# Split by commas to get individual attribute:value pairs
	var pairs = bonus_string.split(",", false)
	
	for pair in pairs:
		# Split by colon to separate attribute and value
		var parts = pair.split(":", false)
		if parts.size() == 2:
			var attribute = parts[0].strip_edges()
			var value = parts[1].strip_edges().to_int()
			result["attributes"].append(attribute)
			result["values"].append(value)
	
	return result

func assign_player_owner(gear: Equipment, player_id: String) -> void:
	# TODO: Implement player lookup by ID
	# This is a stub that will need to be implemented later
	print("TODO: Look up player with ID '" + player_id + "' to assign as gear owner")
	# Example implementation structure:
	# var player = find_player_by_id(player_id)
	# if player:
	#     gear.owning_player = player
	# else:
	#     push_warning("Player with ID '" + player_id + "' not found")

func get_csv_value(row: PackedStringArray, column_indices: Dictionary, column_name: String, default_value = "") -> String:
	if column_indices.has(column_name) and column_indices[column_name] < row.size():
		var value = row[column_indices[column_name]]
		if value != "":
			return value
	return default_value

func get_imported_gear() -> Array[Equipment]:
	return imported_gear

func clear_imported_gear() -> void:
	imported_gear.clear()
