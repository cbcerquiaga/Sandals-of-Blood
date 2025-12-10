extends Node
class_name Character

var player: Player #has all of the bio and the relevant playing attributes
var contract: Contract
var scout_report: ScoutReport
var preferred_job = "player" #favorite job option
var job_roles= { #what staff roles the person is interested in
	"player": true,
	"coach": false,
	"scout": false,
	"security": false,
	"surgeon": false,
	"medic": false,
	"promoter": false,
	"grounds": false,
	"equipment": false,
	"cook": false,
	"accountant": false,
	"entourage": true
}
var home_cooking_style = "bbq"
var day_job = "farm"
var possible_day_jobs = ["none","farm", "blue", "white", "school", "rich", "gang"]#no day job, farming, blue collar work, white collar work, full time student, aristocrat, gangster. Impacts random events
var day_job_pay = 25 #c per week, impacts contract leverage and quality of life for npc
var spouses: int = 0 #spouses who live with the character. has chance to interact like fuck tent; depending on promiscuity rating can cause issues with player home life if the npc cheats on their SO(s). Multiple possible because of weird apocalyptic thruples, polycules, and cults
var children: int = 0 #children who live with the character. more likely to add weight to education and day life in contract focuses
var elders: int = 0 #elders who live with the character. more likely to add weight to housing and welfare state in contract focuses
var adults: int = 0 #brothers, sisters, cousins, friends who live with the character. more likely to add weight to farming and economic contract focuses
var family: int #sum of spouses, children, elders, adults
var possible_cooking_styles = ["bbq", "island", "casserole", "mexican", "vegetarian"]
var gender = "m"
var genders = ["m", "f", "i"] #male, female, intersex
var attracted={ #for use with fuck tent
	"m": true,
	"f": true,
	"i": true
}
var gang_affiliation: String = "none"
var off_attributes ={
	"positivity": 50, #morale increase from good stuff
	"negativity": 50, #morale decrease from bad stuff
	"influence": 50, #how much traits rub off on others
	"promiscuity": 50, #chance of using the fucktent
	"loyalty": 50, #desire to stay with one team
	"love_of_the_game": 50, #weighs winning over material needs if high, weighs material needs over winning if low
	"professionalism": 50, #reduces chance of a negative off-field incident in a given week
	"partying": 50, #chance of partying during the week
	"potential": 50, #max overall as a player
	"hustle": 50, #increases how long a player stays at peak as a player and how quickly they can reach their potential
	"hardiness": 50, #increases chance of surviving off-field incidents
	"combat": 50, #chance of assisting in combat or winning a 1v1 to the death altercation
}

var contract_focuses = {
	#primary focuses
	"value": 0.0, #total earning in contract between wages, bonuses, buyouts, and length
	"stability": 0.0, #contract length, franchise > standard > tradeable > tryout contract type, nobuyout > buy200 > buy100 > buy50 > buyfree buyout
	"flexibility": 0.0, #shorter contract, tradeable > standard > franchise > tryout contract type, [all buyouts] > nobuyout buyout
	#secondary focuses
	"satiety": 0.0, #focus on food value. higher for heavier players
	"hydration": 0.0, #focus on water value
	"hometown": 0.0, #desire to play for hometown team. innate
	"housing": 0.0, #value placed in housing quality
	"house_type": "room", #favored house type
	"gameday": 0.0, #value placed on arena, attendance, and game day amenities
	"travel": 0.0, #value placed on speed and safety of travel
	"medical": 0.0, #value placed on team surgeon and medic. Increases with age and sharply increases after an injury
	"party": 0.0, #value of team's rager rating; after wins in important games
	"chill": 0.0, #value of team's chill rating; after losses, ties, and unimportant games
	"win_now": 0.0, #value based on team's overall ratings, depth, and league position
	"win_later": 0.0, #value placed on number of young prospects, potential of young prospects, and overall and # of players signed to 3 or 4 year contracts
	"loyalty": 0.0, #value placed on team not cutting or trading players
	"opportunity": 0.0, #value placed on team trading or offer sheeting players to higher leagues, on the team's current league relative to the player's goals, and on team overall relative ot other teams in league
	"community": 0.0, #value placed on community projects, charitable giveaways, and city improvements
	"development": 0.0, #value placed on training facilities, coaching staff, projected practice time, and projected playing time
	"safety": 0.0, #value placed on travel security, game day security,  city safety, and teammate toughness ratings
	"education": 0.0, #value placed on quality, cost, and depth of local schools
	"trade": 0.0, #value placed on local trade market, which offers blue collar jobs
	"farming": 0.0, #value placed on farming market, which offers farming jobs and food
	"day_life": 0.0, #value of things to do during the day in the city: parks, activities, hangouts, etc
	"night_life": 0.0, #value of things to do during the night in the city: bars, concerts, drugs, etc
	"welfare": 0.0, #value of welfare state in the city: food, water, money, housing, medicine, transit
}

var top_focuses = []

var staff_skills= {#impacts a character's ability to handle a given staff role
	#coaching
	"physical_training": 10, #ability to increase speed, strength, balance
	"technical_training": 10, #ability to increase striking, 
	"mental_training": 10, #ability to increase reactions, toughness, or change positions
	#scouting
	"talent_eval": 10, #accuracy of scouting, ability to get elite players at tryouts
	"talent_spotting": 10, #thoroughness of scouting, ability to get more players at tryouts
	"scouting_speed": 10, #how long it takes to get info on a player in scouting
	#security
	"deescalation": 10, #prevents issues at home games
	"anti_banditry": 10, #buffs combat on road trips
	"escorting": 10, #ability to keep players out of trouble in town
	#surgery
	"trauma": 10, #reduces chance of death
	"ortho": 10, #speeds up injury recovery time
	"medicine": 10, #reduces chance of illness outbreak
	#medic
	"stretching": 10, #reduces chance of injuries
	"first_aid": 10, #increases likelihood that injured players can stay in the game
	"rehab": 10, #reduces recovery time for post-injury debuffs
	#promoter
	"attraction": 10, #ability to get fans to games
	"sponsorship": 10, #increases frequency and quality of sponsorship offers
	"networking": 10, #increases frequency and quality of tournament invites
	#groundskeeper
	"masonry": 10, #gives homefield advantage for stats like agility and balance, increases speed of field type changes
	"carpentry": 10, #increases speed and reduces cost of facility upgrades
	"painting": 10, #general buff to public-facing already owned facilities
	#equipment manager
	"sewing": 10, #ability to repair damaged equipment
	"carrying": 10, #reduces player exhaustion on road trips, especially when walking
	"acquisitions": 10, #chance of randomly getting new gear
	#cook
	"line_cooking": 10, #increases fan happiness from basic food
	"home_cooking": 10, #increases effect of home cooking bonus for players with the same type
	"fine_cooking": 10, #smooths over issues with sponsors and gangs
	#accountant
	"auditing": 10, #reduces chance of money disappearing
	"budgeting": 10, #reduces cost of consumable purchases
	"bidding": 10, #reduces cost of free agents and staff
	#entourage
	"raging": 10, #increases wild party (post win) rating and effect
	"chilling": 10, #increases chill party (post loss/tie) rating and effect
	"intimacy": 10, #increases energy and confidence gains from fuck tent for those interested in character's gender
	#all staff
	"charisma": 10, #chance that a player will like this staff member, allowing them to use influence to adjust their stats. Doesn't effect if players will put each other in the liked_NPC list, just staff!
	"helpfulness": 10, #chance that other job skills not related to current job buff other staff (ie a coach who can scout helps the scout rating)
	"longevity": 10 #how long the staff can keep working before they have to retire
	
}

var best_league = 0 #0 for never played, 1 for B, 2 for A, 3 for AA, 4 for AAA

var liked_NPCs = [] #all players and staff which the character likes and is influenced by

func get_family_count() -> int:
	family = spouses + children + elders + adults
	return family
