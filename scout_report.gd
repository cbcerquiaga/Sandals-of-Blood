extends Node
class_name ScoutReport

var percentage: int #0-100, determines how much information to give

var info = { #determines what can be revealed based on current level of knowledge
	"comparables": false, #reveals comparable contracts
	"current_contract": false, #reveals current contract
	"pitches": false, #reveals what throws a pitcher has
	"home_cooking_style": false,
	"hometown": false,
	"day_job": false, #reveals type of day job and pay
	"family": false, #reveals spouses, children, elders, adules
	"attraction": false, #reveals attracted
	"gang": false,
	"positivity": false, 
	"negativity": false, 
	"influence": false, 
	"promiscuity": false, 
	"loyalty": false, 
	"love_of_the_game": false, 
	"professionalism": false, 
	"partying": false, 
	"potential": false,
	"hustle": false, 
	"hardiness": false,
	"combat": false,
	"preferred_job": false,
	"career_pooint": false, #reveals growing, peaking, plateauing, fading
	"key_focus": false, #reveals value, stability, loyalty importance
	"secondary_focus": false, #reveals 2nd and 3rd most important focuses
	"tertiary focus": false, #reveals 4th and 5th most important focuses
	"gravy_focus": false, #reveals 6th and 7th most important focuses
	"coach_skills": false, #revealse physical, mental, technical training
	"scout_skills": false, #reveals eval, spotting, and speed
	"security_skills": false, #reveals deescalation, antibanditry, and escorting
	"surgery_skills": false, #reveals trauma, ortho, and medicine
	"medic_skills": false, #reveals stretching, first_aid, and rehab
	"promo_skills": false, #reveals attraction, sponsorship, and networking
	"grounds_skills": false, #reveals masonry, carpentry, and painting
	"kit_skills": false, #reveals sewing, carrying, and aquisitions
	"cook_skills": false, #reveals line, home, and fine cooking
	"money_skills": false, #reveals auditing, budgeting, and bidding
	"party_skills": false, #reveals raging, chilling, and intimacy
	"gen_staff_skills": false, #reveals charisma, helpfulness, and longevity
	"best_league": false, #reveals the best league the player played in
}


func scout(more_percent: int):
	percentage = percentage + more_percent
	if percentage > 100:
		percentage = 100
	generate_report()
	
func generate_report():
	var current_true_count = 0
	for key in info:
		if info[key]:
			current_true_count += 1
	var total_keys = info.size()
	var desired_true_count = int(ceil(float(percentage) * total_keys / 100.0))
	desired_true_count = clamp(desired_true_count, 0, total_keys)
	if current_true_count >= desired_true_count:
		return
	var additional_needed = desired_true_count - current_true_count
	var false_keys = []
	for key in info:
		if not info[key]:
			false_keys.append(key)
	false_keys.shuffle()
	for i in range(min(additional_needed, false_keys.size())):
		var key = false_keys[i]
		info[key] = true
		
func debug_random_scout():
	var rand = randi_range(1,100)
	scout(rand)
