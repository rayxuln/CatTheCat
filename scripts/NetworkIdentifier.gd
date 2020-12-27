extends Node

onready var network_id setget _on_set_network_id
func _on_set_network_id(v):
	network_id = v
	get_parent().name = "NetworkObject_" + str(v)
	
onready var network_manager = GameSystem.game_manager.network_manager

func _ready():
	get_parent().add_to_group("network")
	if network_manager.is_server():
		GameSystem.linking_context.add_node(get_parent())
