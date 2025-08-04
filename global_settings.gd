extends Node

#display
var brightness: float #screen brightness
var game_speed: float #speed of gameplay
var resolution: Vector2
var fullscreen: bool #true = fullscreen false = windowed
#control
var keyboard_control_scheme: String #which control scheme for keyboard
var controller_control_scheme: String
var southpaw: bool #inverts left and right control sticks
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


#profile
var save_file: String #path to save file
var coach: Coach #player character
var franchise: Franchise #team, arena, staff, inventory, relationships
var world_state: Dictionary #leagues, teams, 
var history #player, team, league stats
