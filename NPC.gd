extends Node

var player: Player #has all of the bio and the relevant playing attributes
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
var possible_cooking_styles = ["bbq", "island", "casserole", "cajun", "hawaii"]
var gender = "m"
var genders = ["m", "f", "i"] #male, female, intersex
var attracted={ #for use with fuck tent
	"m": true,
	"f": true,
	"i": true
}
var gang_affiliation
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
	"hustle": 50, #increases how long a player stays at peak as a player
	"talent": 50, #increases how quickly player reaches potential as a player
	"hardiness": 50, #increases chance of surviving off-field incidents
	"combat": 50, #chance of assisting in combat or winning a 1v1 to the death altercation
}

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

var liked_NPCs = [] #all players and staff which the character likes and is influenced by
