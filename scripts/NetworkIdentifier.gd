extends Node

onready var network_id
onready var network_manager = GameSystem.game_manager.network_manager

func _ready():
	get_parent().add_to_group("network")
	if network_manager.is_server():
		GameSystem.linking_context.add_node(get_parent())
