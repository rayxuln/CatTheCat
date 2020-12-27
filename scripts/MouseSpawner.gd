extends Position2D

var Mouse = preload("res://mouse/Mouse.tscn")

func _ready():
	GameSystem.connect("game_start", self, "_on_game_start")


#----- Signals -----
func _on_game_start():
	var n = Mouse.instance()
	n.resource_path = Mouse.resource_path
	get_parent().get_parent().add_child(n)
	n.global_position = global_position
