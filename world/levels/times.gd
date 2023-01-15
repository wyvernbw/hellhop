class_name Times
extends Resource

enum Badge {
	NA = 0,
	BRONZE,
	SILVER,
	GOLD,
	HELLISH,
	SPEED_DEMON
}

@export var bronze: float
@export var silver: float
@export var gold: float
@export var hellish: float
@export var speed_demon: float

func get_badge(time: float) -> int:
	var badge = Badge.NA
	for rank in [bronze, silver, gold, hellish]:
		if time <= rank:
			badge += 1
		else:
			break
	return badge
	
func get_speed_demon(time: float) -> bool:
	if time <= speed_demon:
		return true
	else:
		return false
