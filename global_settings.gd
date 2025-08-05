extends Node
class_name Global_Settings

#display
var brightness: float = 55 #screen brightness
var game_speed: float = 0.35 #speed of gameplay
var resolution: Vector2
var fullscreen: bool = false #true = fullscreen false = windowed
#control
var keyboard_control_scheme: String #which control scheme is used for keyboard
var controller_control_scheme: String #which control scheme is used for controller
var mouse_sensitivity: float #how much the game reacts to mouse movements
var controller_sensitivity: float #how much the game reacts to controller analog stick inputs
#gameplay
var target_score: int #(usually) max score a team can get in the game before the game ends
var pitch_limit: int #(usually) max number of pitches thrown by both teams before a game ends
var human_buff: int #how much to buff all human player attributes
var cpu_buff: int #how much to buff all cpu player attributes
var human_always_pitch: bool #if on, human team always gets to pitch
var special_pitch_frequency: float #increases or decreases groove collection
var injury_frequency: float #how often unjuries occur
var severe_injuries: bool #if players can get crippled, paralyzed, or killed in game
#audio
var tracks: Dictionary #"title": bool format, whether or not particular songs play in the menu
var master_vol: float
var music_vol: float #volue of menu music
var sfx_vol: float #sound effects of players in the game- footsteps, contact with ball, player voices
var crowd_vol: float #cheering, chanting, bands, announcers
var stereo: bool #whether the same sound comes out of every speaker or it is different from the left and right
#career
var survival_difficulty: int #code for how tough it is to survive the wasteland
var travel_danger: int #code for how dangerous it is to travel
var signing_difficulty: int #how tough it is to convince players to sign with you, how much they are willing to haggle, how likely other teams match offer sheets
var management_difficulty: int #how much players will try to leave, cause problems; how much xp players get, quality of auto-generated players, cost of improvements, difficulty of managing relationships with players, other teams, gangs, and fans
var poaching: bool #if other teams will deliberately try to sign your players when you have no money or you're otherwise vulnerable

#profile
var save_file: String #path to save file
var coach: Coach #player character
var franchise: Franchise #team, arena, staff, inventory, relationships
var world_state: Dictionary #leagues, teams, 
var history #player, team, league stats

func transfer_settings(other_settings: Global_Settings):
	brightness = other_settings.brightness
	game_speed = other_settings.game_speed
	resolution = other_settings.resolution
	keyboard_control_scheme = other_settings.keyboard_control_scheme
	controller_control_scheme = other_settings.controller_control_scheme
	target_score = other_settings.target_score
	pitch_limit = other_settings.pitch_limit
	human_buff = other_settings.human_buff
	cpu_buff = other_settings.cpu_buff
	human_always_pitch = other_settings.human_always_pitch
	special_pitch_frequency = other_settings.special_pitch_frequency
	injury_frequency = other_settings.injury_frequency
	severe_injuries = other_settings.severe_injuries
	tracks =other_settings.tracks
	master_vol = other_settings.master_vol
	music_vol = other_settings.music_vol
	sfx_vol = other_settings.music_vol
	crowd_vol = other_settings.crowd_vol
	stereo = other_settings.stereo
	survival_difficulty = other_settings.survival_difficulty
	travel_danger = other_settings.travel_danger
	signing_difficulty = other_settings.signing_difficulty
	management_difficulty = other_settings.management_difficulty
	poaching = other_settings.poaching
